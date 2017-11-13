#!/bin/bash
#############################################################################################################################
# This code contains copyright information which is the proprietary property
# of SITA Information Network Computing Limited (SITA). No part of this
# code may be reproduced, stored or transmitted in any form without the prior
# written permission of SITA.
#
# Copyright (C) SITA Information Network Computing Limited 2013.
# All rights reserved.
#
# Description:
#
#############################################################################################################################

shopt -s extglob

BASE_DIR=$(cd $(dirname $0);pwd)
export BASE_DIR=${BASE_DIR}


. ${BASE_DIR}/utils/utils.sh


#
# Set the inventory location
#
set_inventory
RC=${?}
if [ ${RC} -ne 0 ]; then
	exit 1
fi

#
# Validate arguments from the command line
#

function validate_args
{
 if [  -z "${APP_NAME}" ]
 then
    echo "ERROR: Application name missing" 
    return 1
 fi

 if [  -z "${APP_VERSION}" ]
 then
    echo "ERROR: Application version missing" 
    return 1
 fi

 if [  -z "${DEPLOY_MODE}" ]
 then
    echo "ERROR: Deploy mode missing, should be either DRYRUN or COMMIT"
    return 1
 fi
 
 if [  -z "${INSTALL_TYPE}" ]
 then
    echo "ERROR: Install type is  missing" 
    return 1
 fi

 if [ -z "${EAR_DIR}" ]; then
    echo "ERROR: EAR_DIR is missing" 
    return 1
 elif [ ! -d "${EAR_DIR}" ]; then
	  echo "ERROR: Invalid EAR_DIR - ${EAR_DIR} does not exist" 
	  return 1
 fi

 if [ -z "${ADMIN_USER}" ]; then
    echo "ERROR: ADMIN_USER is missing" 
    return 1
 fi

 if [ -z "${DOMAIN_TYPE}" ]; then
    echo "ERROR: DOMAIN_TYPE is missing" 
    return 1
 elif [[ ${DOMAIN_TYPE} != @(WLS|OSB) ]]; then
    echo "ERROR: Invalid DOMAIN_TYPE, can be either WLS or OSB" 
    return 1
 fi

 get_password
 
}

function print_usage
{
 echo "Usage: $0 [options]
 Options      Purpose
 -h           Display help
 -n           Application Name
 -v           Application Version
 -d           EAR File(s) location - Absolute Path
 -u           WL Admin Console User
 -t	      Target Type (WLS or OSB)
 -m           Deployment Mode ( DRYRUN or COMMIT )"
}

#
# Read ear directory 
#

function read_ear_dir
{
	EAR_COUNT=`ls ${EAR_DIR} | wc -l`
	if [ $EAR_COUNT -eq 0 ]; then
		echo "WARNING: No files found in ${EAR_DIR} to deploy" 
		return 2	
	fi
        EAR_TARGET_CLUSTER_COUNT=0
	local ctr=0 ;
 	for FILE in `ls ${EAR_DIR}/`
	do
		local VERSIONLESS_NAME=$(echo ${FILE} | egrep -o \(\([[:alpha:]]\)+\)?\(\-\([[:alpha:]]\)+\)* )
                local FILE_EXTN=$(echo ${FILE} | egrep -o  \(\\.ear\|\\.war\) )

		EAR_NAME[${ctr}]=$VERSIONLESS_NAME
		EAR_TARGET_DOMAIN_TYPE[${ctr}]=${DOMAIN_TYPE}
		EAR_EXTN=${FILE_EXTN}
		EAR_DEPLOY_NAME[${ctr}]=${EAR_NAME[${ctr}]}-${MAJOR_VERSION}
               #Target-Cluster 
                # Get the Target Cluster from manifest, set default to APP
                local TARGETS=`${JAVA_HOME}/bin/java -Dpython.cachedir=/tmp/${DEPLOY_USER} org.python.util.jython ${BASE_DIR}/wlst/get-manifest-info.py ${EAR_DIR}/${FILE} Target-Cluster`
         
                EAR_TARGET_CLUSTER_COUNT[${ctr}]=0
                if [ -z "${TARGETS}" ]; then
                   EAR_TARGET_CLUSTER_TYPE[${ctr}, 0]=${TARGET_CLUSTER}
                else
                   TARGET_CLUSTER_ARRAY=$(echo $TARGETS | tr "," "\n")
                   if [ ! -z "${TARGET_CLUSTER_ARRAY}" ]; then
                      local counter=0
                      for TARGET_CLUSTER_VALUE in $TARGET_CLUSTER_ARRAY
                      do
                         EAR_TARGET_CLUSTER_TYPE[$ctr, ${counter}]=${TARGET_CLUSTER_VALUE}
                         counter=$((${counter}+1));
                      done
                      EAR_TARGET_CLUSTER_COUNT[${ctr}]=${counter}
                   else
                      EAR_TARGET_CLUSTER_TYPE[${ctr}, 0]=${TARGET_CLUSTER}
                   fi
                fi
                

		# Find the deploy DOMAIN for the ear
		eval DOMAIN_NAME=\$${EAR_TARGET_DOMAIN_TYPE[$ctr]}_DOMAIN_NAME
		if [ -z "${DOMAIN_NAME}" ]; then
                   echo "ERROR: Could not find DOMAIN_NAME for : ${EAR_DEPLOY_NAME[$ctr]}" 
		   return 1
		else
		    EAR_TARGET_DOMAIN_NAME[${ctr}]=${DOMAIN_NAME}
		fi

		# Find the deploy CLUSTER for the ear
		eval CLUSTER_NAME=\$${EAR_TARGET_DOMAIN_TYPE[$ctr]}_CLUSTER_${EAR_TARGET_CLUSTER_TYPE[$ctr, 0]}
		if [ -z "${CLUSTER_NAME}" ]; then
		   echo "ERROR: Could not find CLUSTER_NAME for : ${EAR_DEPLOY_NAME[$ctr]}" 
		   return 1
		else
		    EAR_TARGET_CLUSTER_NAME[${ctr}]=${CLUSTER_NAME}
		fi

		EAR_FILE_PATH[${ctr}]=$APP_INSTALL_PATH/$DOMAIN_NAME/${EAR_DEPLOY_NAME[${ctr}]}/app/${EAR_DEPLOY_NAME[${ctr}]}${FILE_EXTN}
		EAR_DEPLOY_PLAN[${ctr}]=$APP_INSTALL_PATH/$DOMAIN_NAME/${EAR_DEPLOY_NAME[${ctr}]}/plan/Plan.xml

		# Get the deploy-order from manifest, set default to 100
		local DEPLOY_ORDER=`${JAVA_HOME}/bin/java -Dpython.cachedir=/tmp/${DEPLOY_USER} org.python.util.jython ${BASE_DIR}/wlst/get-manifest-info.py ${EAR_DIR}/${FILE} Deploy-Order`
		if [ -z "${DEPLOY_ORDER}" ]; then
		   DEPLOY_ORDER=100
		fi		
                EAR_DEPLOY_ORDER[${ctr}]=${DEPLOY_ORDER}

		# Check if ear is already deployed
		#echo "${WLST} ${BASE_DIR}/wlst/get-deploy-status.py  ${ADMIN_USER} ${ADMIN_PASSWORD} ${ADMIN_URL} app "${EAR_DEPLOY_NAME[${ctr}]}""
                #${WLST} ${BASE_DIR}/wlst/get-deploy-status.py  ${ADMIN_USER} ${ADMIN_PASSWORD} ${ADMIN_URL} app "${EAR_DEPLOY_NAME[${ctr}]}" > /dev/null
                #local RC=${?}
                #EAR_ALREADY_DEPLOYED[${ctr}]=${RC}

		#ctr=$((${ctr}+1));
	done


  for (( ord=50;ord<=150;ord++))
  do
    for((ctr=0; ctr<$EAR_COUNT; ctr++))
    do
      if [ ${ord} -ne ${EAR_DEPLOY_ORDER[$IDX]} ]; then
         continue
      fi
      echo "Deployable: ${EAR_DEPLOY_NAME[${ctr}]} with deploy-order [${EAR_DEPLOY_ORDER[${ctr}]}]"
    done
  done
}


#
# Validate deployable for upgrade
#
function validate_upgrade
{

 local IDX=0
 for (( IDX =0 ; IDX < $EAR_COUNT ; IDX ++ ))
 do
     echo -n "Validating for upgrade ${EAR_DEPLOY_NAME[$IDX]}..." 

     # Check if EAR already deployed
     if [ ${EAR_ALREADY_DEPLOYED[${IDX}]} -eq 1 ]; then
        echo "FAILED, no such application exists" 
        return 1
     fi
      

     # Check if EAR deployed from same location
     for HOST in ${HOSTS}
     do
       local INSTALL_LOC=$APP_INSTALL_PATH/${EAR_TARGET_DOMAIN_NAME[$IDX]}/${EAR_DEPLOY_NAME[$IDX]}/app/${EAR_DEPLOY_NAME[$IDX]}${EAR_EXTN[$IDX]}
       local APP_EXISTS=`ssh -q ${DEPLOY_USER}@$HOST "test -f ${INSTALL_LOC} && echo exists"`
       if [ -z "${APP_EXISTS}" ]; then
          echo "FAILED, install location is not ${INSTALL_LOC}" 
          return 1
       fi
     done

    echo "Found OK" 

 done
}

#
# Create default plan 
#

function createDefaultPlan
{
 local DEPLOY_NAME=$1
 local APP_HOME=$2
 local PLAN_FILE=${EAR_WORK_AREA}/applications/${DEPLOY_NAME}/${DEFAULT_PLAN}
 cp ${BASE_DIR}/template/Plan_template.xml ${PLAN_FILE}
 RC=${?}
 if [ ${RC} == 0 ];then
    sed -i "s/APPNAME/${DEPLOY_NAME}/g" ${PLAN_FILE}
    RC=${?}
    if [ ${RC} == 0 ];then
       sed -i "s|CONFIGROOT|${APP_HOME}/${DEPLOY_NAME}/plan|g" ${PLAN_FILE}
	    RC=${?}
	    if [ ${RC} != 0 ];then
          echo "Error occurred while creating default plan - substituing config root"
          return 2
       fi
    else
        echo "Error occurred while creating default plan - substituting app name" 
        return 2
    fi
 else
     echo "ERROR: Could not create plan file for : ${DEPLOY_NAME}" 
     return 2
 fi
}

#
# Get ear index
#

function get_ear_index
{
	local ctr=0
	for (( ctr=0; ctr<${EAR_COUNT};ctr++ ))
	do	
		if [ ${EAR_NAME[${ctr}]} == $1 ]; then
			return $ctr
		fi
	done
	return -1
}

#
# Staging the deployables on the hosts
#

function stage_deployables
{

 for FILE in `ls ${EAR_DIR}/`
 do
   # Set enviorment params
   setEnvParams ${EAR_TARGET_DOMAIN_TYPE[$EAR_INDEX]}

   local VERSIONLESS_NAME=$(echo ${FILE} | egrep -o \(\([[:alpha:]]\)+\)?\(\-\([[:alpha:]]\)+\)* )
   get_ear_index ${VERSIONLESS_NAME}
   local EAR_INDEX=${?}
   if [ $EAR_INDEX -eq -1 ]; then
      echo "ERROR: Could not find index for : ${FILE}" 
      return 1
   fi

   local DEPLOY_NAME=${EAR_DEPLOY_NAME[$EAR_INDEX]}
   local FILE_EXTN=$(echo ${FILE} | egrep -o  \(\\.ear\|\\.war\) )
   EAR_EXTN=${FILE_EXTN}

   # Create the folder structure in the work area
   mkdir -p ${EAR_WORK_AREA}/applications/${DEPLOY_NAME}
   mkdir -p ${EAR_WORK_AREA}/${DEPLOY_NAME}/app ${EAR_WORK_AREA}/${DEPLOY_NAME}/plan


   # Create the default plan
   createDefaultPlan ${DEPLOY_NAME} ${APP_INSTALL_PATH}/${EAR_TARGET_DOMAIN_NAME[$EAR_INDEX]}
   RC=${?}
   if [ ${RC} -ne 0 ]; then
      return 1
   fi   

   # Copy the ear per deploy structure
   cp -p ${EAR_DIR}/${FILE} ${EAR_WORK_AREA}/applications/${DEPLOY_NAME}/${FILE}
   RC=${?}
   if [ $RC -ne  0 ];then
      echo "Could not copy ${FILE} to ${EAR_WORK_AREA}/applications/${DEPLOY_NAME}/${FILE}" 
      return ${RC}
   fi

   # Create the symlinks in the work area for ear and Plan.xml
   ln -s $APP_INSTALL_PATH/${EAR_TARGET_DOMAIN_NAME[$EAR_INDEX]}/applications/$DEPLOY_NAME/$FILE  $EAR_WORK_AREA/$DEPLOY_NAME/app/$DEPLOY_NAME${EAR_EXTN}
   ln -s $APP_INSTALL_PATH/${EAR_TARGET_DOMAIN_NAME[$EAR_INDEX]}/applications/$DEPLOY_NAME/Plan.xml $EAR_WORK_AREA/$DEPLOY_NAME/plan/Plan.xml

   if [ -z "${HOSTS}" ]; then
      echo "ERROR: Could not find the TARGET HOSTS" 
      exit 1
   fi

   #echo -n "Staging ${EAR_DEPLOY_NAME[$EAR_INDEX]} ..."
   for HOST in $HOSTS
   do
     if [[ ${DOMAIN_TYPE} != @(WLS) ]]; then	
	DEPLOYER_USER=osb
     else
	DEPLOYER_USER=weblogic
     fi			
     rsync -rcalq --exclude=.svn/ -e "ssh -q" $DRY_RUN $EAR_WORK_AREA/ ${DEPLOYER_USER}@$HOST:$APP_INSTALL_PATH/${EAR_TARGET_DOMAIN_NAME[$EAR_INDEX]}/
     # --log-file=${LOG_FILE_PATH}/${LOG_FILE}
     RC=${?}
     if [ ${RC} -ne 0 ]; then
	#echo "FAILED"
        return 1
     fi
   done
   #echo "Done" 
 done

}

#
# Deploy EAR file(s) 
#

function deployEar
{

 echo -e "Inside deployEar"
 local IDX=0

 for ((ord=50;ord<=150;ord++))
 do

 for((IDX=0; IDX<$EAR_COUNT; IDX++))
 do
   if [ ${ord} -ne ${EAR_DEPLOY_ORDER[$IDX]} ]; then
      continue
   fi

   initEnv ${EAR_TARGET_DOMAIN_TYPE[$IDX]}
   DEPLOY_OPTS="-name ${EAR_DEPLOY_NAME[$IDX]}"
   DEPLOY_OPTS="${DEPLOY_OPTS} -source ${EAR_FILE_PATH[$IDX]}"
   DEPLOY_OPTS="${DEPLOY_OPTS} -plan ${EAR_DEPLOY_PLAN[$IDX]}"
   DEPLOY_OPTS="${DEPLOY_OPTS} -id `date +"%Y%m%d%H%M%S"`"
   DEPLOY_OPTS="${DEPLOY_OPTS} -targets ${EAR_TARGET_CLUSTER_NAME[$IDX]}"
   DEPLOY_OPTS="${DEPLOY_OPTS} -adminurl ${ADMIN_URL}"
   DEPLOY_OPTS="${DEPLOY_OPTS} -username ${ADMIN_USER}" 
   DEPLOY_OPTS="${DEPLOY_OPTS} -password ${ADMIN_PASSWORD}"

   if [ ${EAR_ALREADY_DEPLOYED[${IDX}]} -eq 1 ]; then
       DEPLOY_ACTION="deploy"
       DEPLOY_OPTS="${DEPLOY_OPTS} -nostage "
   else
       DEPLOY_ACTION="redeploy"	
   fi

   DEPLOYED_LST="${DEPLOYED_LST} ${EAR_DEPLOY_NAME[$IDX]}"

   echo -n "Deploying ${EAR_DEPLOY_NAME[$IDX]}..." 

   ${JAVA_HOME}/bin/java weblogic.Deployer -${DEPLOY_ACTION} ${DEPLOY_OPTS} > deploy-temp-ear.log
   RC=${?}
   cat deploy-temp-ear.log >> ${LOG_FILE_PATH}/${LOG_FILE}
   if [ ${RC} -ne 0 ]; then
       echo "Failed" 
       cat deploy-temp-ear.log
       if [ -f "deploy-temp-ear.log" ]; then 
          rm deploy-temp-ear.log
          break;
       fi
   else
       echo "Done" 
       if [ -f "deploy-temp-ear.log" ]; then
          rm deploy-temp-ear.log
       fi

       # Update inventory
       update_app_inventory ${APP_NAME} ${MAJOR_VERSION} ${EAR_TARGET_DOMAIN_TYPE[$IDX]} ${EAR_DEPLOY_NAME[$IDX]}

       # Update the deploy-order in WL
       ${WLST}  ${BASE_DIR}/wlst/set-deploy-order.py ${ADMIN_USER} ${ADMIN_PASSWORD} ${ADMIN_URL} app "${EAR_DEPLOY_NAME[$IDX]}" ${EAR_DEPLOY_ORDER[$IDX]} > /dev/null
       RC=${?}
       if [ ${RC} -ne 0 ]; then
           echo "WARNING: Could not set the deploy-order to ${EAR_DEPLOY_ORDER[$IDX]} for : ${EAR_DEPLOY_NAME[$IDX]}, please make the change through WL Console" 
       fi

       if [ ${EAR_TARGET_CLUSTER_COUNT[$IDX]} -eq 0 ]; then       
           CLUSTER_TYPE_NAME=""
       else
           for((COUNTER=0; COUNTER<${EAR_TARGET_CLUSTER_COUNT[$IDX]}; COUNTER++))
           do
              eval CLUSTER_EVAL_NAME=\$${EAR_TARGET_DOMAIN_TYPE[$IDX]}_CLUSTER_${EAR_TARGET_CLUSTER_TYPE[${IDX}, ${COUNTER}]}
              if [ ${COUNTER} -eq 0 ]; then
                  CLUSTER_TYPE_NAME=${CLUSTER_EVAL_NAME}
              else
                  CLUSTER_TYPE_NAME="${CLUSTER_TYPE_NAME}#${CLUSTER_EVAL_NAME}"  
              fi
           done
       fi

       if [ ! -z "${CLUSTER_TYPE_NAME}" ]; then
          ${BASE_DIR}/set-target-cluster.sh -n ${EAR_DEPLOY_NAME[${IDX}]} -c ${CLUSTER_TYPE_NAME} -l ${ADMIN_URL} -u ${ADMIN_USER} -t "APP"
       fi
   fi
 done
   if [ ${RC} -ne 0 ]; then
      break;
   fi
 done
 if [ ${DEPLOY_MODE} == "COMMIT" ]; then
    # Update inventory conf in inventory directory
    update_deploy_inventory ${APP_NAME} ${MAJOR_VERSION}
 fi

 return ${RC} 
 
}


#
# Option from command line 
#

while getopts :n:v:m:d:u:t: o
do case "$o" in
   n)   APP_NAME=$OPTARG;;
   v)   APP_VERSION=$OPTARG;;
   m)   DEPLOY_MODE=$OPTARG;;
   d)   EAR_DIR=$OPTARG;;
   u)   ADMIN_USER=$OPTARG;;
   t)   DOMAIN_TYPE=$OPTARG;;
   [?])   print_usage
          exit 1;;
   esac
done

#
# Validate command line arguments
#
validate_args
RC=${?}
if [ ${RC} -ne 0 ]; then
   print_usage
   exit 1
fi

# Initialize the logging
initlog

#
# Validate application name which is given in app.conf file
#
validate_app_name
RC=${?}
if [ ${RC} -ne 0 ]; then
        echo "ERROR: ${APP_NAME} does not exists in the app.conf, please check ${APP_NAME}."
        exit 1
fi

# Set the classapth for Jython
CLASSPATH=${FMW_HOME}/oracle_common/util/jython/jython.jar
export CLASSPATH

setEnvParams ${DOMAIN_TYPE}
initEnv ${DOMAIN_TYPE}

# Set the najor version
MAJOR_VERSION=`echo ${APP_VERSION} | awk -F "." '{print $1}'`


# Read Details of deployables 
#
read_ear_dir
RC=${?}
if [ ${RC} -ne 0 ]; then
   exit 1
fi


#
# Validate  if the app is applicable for upgrade
#
if [ ${INSTALL_TYPE} == "ROLLING_UPGRADE" ]; then

   # Validate the EARs for current major version
   validate_upgrade
   RC=${?}
   if [ ${RC} -ne 0 ]; then
      exit 1
   fi
fi

# Create the work area
EAR_WORK_AREA=${TMP_DIR}/ear_work_area
if [ -z "${EAR_WORK_AREA}" ]; then
        EAR_WORK_AREA=$(mktemp -d -p ${TMP_DIR} ear_`date +"%Y%m%d%H%M"`)
        if [ ! -d ${EAR_WORK_AREA} ]; then
                mkdir -p ${EAR_WORK_AREA}
                RC=${?}
                if [ ${RC} -ne 0 ]; then
                        echo "Could not create temp directory : ${EAR_WORK_AREA}" 
                        exit 1
                fi
        fi
fi

if [ ${DEPLOY_MODE} != "COMMIT" ]; then
    DRY_RUN="--dry-run"
else
     DRY_RUN=""
fi


#
# Stage the deployables in the sita-apps
#
stage_deployables
RC=${?}
# Clean the work area
if [ -d $EAR_WORK_AREA ]; then
   rm -rf $EAR_WORK_AREA
fi

if [ ${RC} -ne 0 ]; then
   echo "ERROR: Could not stage deployables" 
   exit 1
fi

if [ ${DEPLOY_MODE} != "COMMIT" ]; then
   echo "Done" 
   exit 0
fi



#
# Deploy if in INSTALL Mode or UPGRADE Immediate
#
if [ ${INSTALL_TYPE} == "IMMEDIATE_UPGRADE" ]; then
   deployEar
   RC=${?}
   if [ $RC -ne 0 ]; then
       exit 1
   fi
fi


# Rolling Restarting Managed servers
if [ ${INSTALL_TYPE} == "ROLLING_UPGRADE" ]; then
   
   ${BASE_DIR}/rolling-restart.sh -u ${ADMIN_USER} -t ${DOMAIN_TYPE} -c ${TARGET_CLUSTER} 
   RC=${?}
   if [ $RC -ne 0 ]; then
       exit 1
   fi
   echo "Done" 
fi
