#This script will deploy resources, EAR and OSB in specified environment
#To run the script: ./run-deploy.sh <App_Name> <App_Version> <Environment> <Deployment_Type>

#<APP_Name>: Name of The Application For WTRUI its: wtrui
#<APP_Version>: Application version which needs to be deployed. This has to be in single digit. 
#		For Ex: if Application Version is 0.9.0.17 <App_Version> will be : 0
#<Environment>: Environment in which Application needs to be deployed (WTRUIDEV, WTRUIINT, WTRUIPERF, WTRUIQA)
#<Deployment_Type>: Deployment can be from (EAR, OSB, BOTH)
#		    EAR: used only when service deployment is required
#		    OSB: used only when osb jar deployment is required
#		    BOTH: used when both service and osb jar needs to be deployed

#######################################################################
#Sample execution of the script: ./run-deploy.sh wtrui 0 WTRUIINT BOTH
#######################################################################
#!/bin/sh


BASE_DIR=$(cd $(dirname $0);pwd)
export BASE_DIR=${BASE_DIR}


. ${BASE_DIR}/utils/utils.sh
. ${BASE_DIR}/read_password.sh

cd /home/oracle/scripts/deploy-scripts-3.7.0
cp ./conf/env.conf_$3 ./conf/env.conf
. conf/env.conf


if [ "$4" == "EAR" ]; then

	echo "Resources Deployment................. "
      ./deploy-resources_WTRUI.sh -n $1 -v $2 -s /home/oracle/downloads/$1/$3/wls/ -m COMMIT -t WLS
#	echo "Undeploying old EAR..................."
     #  ./undeploy-ear.sh -n $1 -v $2 -m COMMIT -u $CONSOLE_USER

	echo "EAR deployment........................"
	./deploy-eartest.sh -n $1 -v $2 -d /home/oracle/downloads/$1/wls/ -u $CONSOLE_USER -t WLS -m COMMIT


elif [ "$4" == "OSB" ]; then

	echo "Undeploying OSB jar..............."
	#./undeploy-osbconfig.sh -n $1 -v $2 -m COMMIT -u $CONSOLE_USER	
	echo "Deploying OSB jar................."
	./deploy-osbconfig.sh -n $1 -v $2 -d /home/oracle/downloads/$1/osb/ -c /home/oracle/downloads/$1/$3/osb/ -u $CONSOLE_USER -m COMMIT

	
elif [ "$4" == "BOTH" ]; then

	echo "======================================================================================"
	echo "=================================EAR Deployment======================================="
	echo "======================================================================================"
	echo "Resources Deployment................. "
        ./deploy-resources_WTRUI.sh -n $1 -v $2 -s /home/oracle/downloads/$1/$3/wls/ -m COMMIT -t WLS
        echo "Undeploying old EAR..................."
        ./undeploy-ear.sh -n $1 -v $2 -m COMMIT -u $CONSOLE_USER

        echo "EAR deployment........................"
        ./deploy-ear.sh -n $1 -v $2 -d /home/oracle/downloads/$1/wls/ -u $CONSOLE_USER -t WLS -m COMMIT
	
	echo "======================================================================================"
        echo "=================================OSB Deployment======================================="
        echo "======================================================================================"

	echo "Undeploying OSB jar..............."
        ./undeploy-osbconfig.sh -n $1 -v $2 -m COMMIT -u $CONSOLE_USER
        echo "Deploying OSB jar................."
        ./deploy-osbconfig.sh -n $1 -v $2 -d /home/oracle/downloads/$1/osb/ -c /home/oracle/downloads/$1/$3/osb/ -u $CONSOLE_USER -m COMMIT

else

	echo "Enter proper Deployment type"
fi
