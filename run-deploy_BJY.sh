#!/bin/sh
BASE_DIR=$(cd $(dirname $0);pwd)
export BASE_DIR=${BASE_DIR}


. ${BASE_DIR}/utils/utils.sh
. ${BASE_DIR}/read_password.sh

cd /home/oracle/scripts/deploy-scripts-3.7.0
cp ./conf/env.conf_$3 ./conf/env.conf
. conf/env.conf

if  [ "$5" == "EAR" ]; then
     echo "WLS resource deployment...... "
     ./deploy-resources.sh -n $1 -v $2 -s /home/oracle/downloads/$1/$3/wls -m COMMIT -t WLS
    
     echo "Hazelcast resource deployment....."
     ./deploy-hazelcast.sh -n $1 -v $2 -s /home/oracle/downloads/$1/$3 -m COMMIT -t WLS -p $4

     echo "Undeploying WLS Artifacts ........."
     ./undeploy-ear.sh -n $1 -v $2 -m COMMIT -u $CONSOLE_USER

     echo "Deploying the EAR......"
     ./deploy-ear.sh -n $1 -v $2 -d /home/oracle/downloads/$1/wls -u $CONSOLE_USER -t WLS -m COMMIT

elif [ "$5" == "OSB" ]; then
    
    echo "WLS resource deployment...... "
    ./deploy-resources.sh -n $1 -v $2 -s /home/oracle/downloads/$1/$3/osb -m COMMIT -t OSB

    echo "Deploying the web....."
    ./deploy-ear.sh -n $1 -v $2 -d /home/oracle/downloads/$1/web -u $CONSOLE_USER -t OSB -m COMMIT

    echo "Undeploying OSB jars ........."
    ./undeploy-osbconfig.sh -n $1 -v $2 -m COMMIT -u $CONSOLE_USER

    echo "Deploying the OSB jars..."
    ./deploy-osbconfig.sh -n $1 -v $2 -d /home/oracle/downloads/$1/osb -c /home/oracle/downloads/$1/$3/osbcust -u $CONSOLE_USER -m COMMIT


else
   echo "Enter the proper deployment type"

fi

