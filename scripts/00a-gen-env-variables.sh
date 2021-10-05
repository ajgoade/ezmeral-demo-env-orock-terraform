#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

[ -e ./generated/env-variables ] && rm ./generated/env-variables
env_variables=./generated/env-variables

export LOCAL_SSH_PUB_KEY_PATH=./generated/controller.pub_key
echo LOCAL_SSH_PUB_KEY_PATH=$LOCAL_SSH_PUB_KEY_PATH >> $env_variables
export LOCAL_SSH_PRV_KEY_PATH=./generated/controller.prv_key
echo LOCAL_SSH_PRV_KEY_PATH=$LOCAL_SSH_PRV_KEY_PATH >> $env_variables

export CA_KEY=./generated/ca-key.pem
echo CA_KEY=$CA_KEY >> $env_variables
export CA_CERT=./generated/ca-cert.pem
echo CA_CERT=$CA_CERT >> $env_variables

export INSTALL_WITH_SSL=True
echo INSTALL_WITH_SSL=$INSTALL_WITH_SSL >> $env_variables

export EMBEDDED_DF=False
echo EMBEDDED_DF=$EMBEDDED_DF >> $env_variables

export CREATE_EIP_GATEWAY=True
echo CREATE_EIP_GATEWAY=$CREATE_EIP_GATEWAY >> $env_variables

export AD_SERVER_ENABLED=True
echo AD_SERVER_ENABLED=$AD_SERVER_ENABLED >> $env_variables
export AD_INSTANCE_ID=$(nova list |grep adserver | awk '{print $2}')
echo AD_INSTANCE_ID=$AD_INSTANCE_ID >> $env_variables
export AD_PRV_IP=$(nova list |grep adserver | awk '{ split($12, v, "="); print v[2]}')
echo AD_PRV_IP=$AD_PRV_IP >> $env_variables
export AD_PUB_IP=$(nova list |grep adserver | awk '{ split($12, v, "="); print v[2]}')
echo AD_PUB_IP=$AD_PUB_IP >> $env_variables
export AD_MEMBER_GROUP=DemoTenantUsers
echo AD_MEMBER_GROUP=$AD_MEMBER_GROUP >> $env_variables
export AD_ADMIN_GROUP=DemoTenantAdmins
echo AD_ADMIN_GROUP=$AD_ADMIN_GROUP >> $env_variables

export RDP_SERVER_ENABLED=False
echo RDP_SERVER_ENABLED=$RDP_SERVER_ENABLED >> $env_variables


export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo SCRIPT_DIR=$SCRIPT_DIR >> $env_variables
export PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo PROJECT_DIR=$SCRIPT_DIR >> $env_variables
export PREFIX_ID=$(cat ./etc/*tfvars|grep username|awk '{print $3}'|awk '{print substr($0,2,3)}')
export PROJECT_ID=$(echo $PREFIX_ID-ecp)
echo PROJECT_ID=$PROJECT_ID >> $env_variables

export CTRL_INSTANCE_ID=$(nova list |grep controller | awk '{print $2}')
echo CTRL_INSTANCE_ID=$CTRL_INSTANCE_ID >> $env_variables
export CTRL_PRV_IP=$(nova list |grep controller | awk '{ split($12, v, "="); print v[2]}')
echo CTRL_PRV_IP=$CTRL_PRV_IP >> $env_variables
export CTRL_PUB_IP=$(nova list |grep controller | awk '{ split($12, v, "="); print v[2]}')
echo CTRL_PUB_IP=$CTRL_PRV_IP >> $env_variables
export CTRL_PRV_DNS=$(nova list |grep controller | awk '{ split($12, v, "="); print $4".demo.com"}')
echo CTRL_PRV_DNS=$CTRL_PRV_DNS >> $env_variables
export CTRL_PUB_DNS=$(nova list |grep controller | awk '{ split($12, v, "="); print $4".demo.com"}')
echo CTRL_PUB_DNS=$CTRL_PUB_DNS >> $env_variables
export CTRL_PUB_HOST=$(nova list |grep controller | awk '{ split($12, v, "="); print $4".demo.com"}')
echo CTRL_PUB_HOST=$CTRL_PUB_HOST >> $env_variables
export CTRL_PRV_HOST=$(nova list |grep controller | awk '{ split($12, v, "="); print $4".demo.com"}')
echo CTRL_PRV_HOST=$CTRL_PRV_HOST >> $env_variables

export GATW_INSTANCE_ID=$(nova list |grep gateway | awk '{print $2}')
echo GATW_INSTANCE_ID=$GATW_INSTANCE_ID >> $env_variables
export GATW_PRV_IP=$(nova list |grep gateway | awk '{ split($12, v, "="); print v[2]}')
echo GATW_PRV_IP=$GATW_PRV_IP >> $env_variables
export GATW_PUB_IP=$(nova list |grep gateway | awk '{ split($12, v, "="); print v[2]}')
echo GATW_PUB_IP=$GATW_PUB_IP >> $env_variables
export GATW_PRV_DNS=$(nova list |grep gateway | awk '{ split($12, v, "="); print $4".demo.com"}')
echo GATW_PRV_DNS=$GATW_PRV_DNS >> $env_variables
export GATW_PUB_DNS=$(nova list |grep gateway | awk '{ split($12, v, "="); print $4".demo.com"}')
echo GATW_PUB_DNS=$GATW_PUB_DNS >> $env_variables
export GATW_PUB_HOST=$(nova list |grep gateway | awk '{ split($12, v, "="); print $4".demo.com"}')
echo GATW_PUB_HOST=$GATW_PUB_HOST >> $env_variables
export GATW_PRV_HOST=$(nova list |grep gateway | awk '{ split($12, v, "="); print $4".demo.com"}')
echo GATW_PRV_HOST=$GATW_PRV_HOST >> $env_variables

if [[ "$RDP_SERVER_ENABLED" == "True" ]]; then
   export RDP_INSTANCE_ID=$(nova list |grep rdpserver | awk '{print $1}')
   echo RDP_INSTANCE_ID=$RDP_INSTANCE_ID >> $env_variables
   export RDP_PRV_IP=$(nova list |grep rdpserver | awk '{ split($12, v, "="); print v[2]}')
   echo RDP_PRV_IP=$RDP_PRV_IP >> $env_variables
   export RDP_PUB_IP=$(nova list |grep rdpserver | awk '{ split($12, v, "="); print v[2]}')
   echo RDP_PUB_IP=$RDP_PUB_IP >> $env_variables
else
   RDP_INSTANCE_ID=""
fi

WORKER_COUNT=$(nova list|grep k8s|wc -l)

if [[ "$WORKER_COUNT" != "0" ]]; then
   export WRKR_INSTANCE_IDS=$(nova list |grep k8s | awk '{ split($12, v, "="); print $2}'|awk 'BEGIN { ORS = " " } { print }')
   export WRKR_PRV_IPS=$(nova list |grep k8s | awk '{ split($12, v, "="); print v[2]}'|awk 'BEGIN { ORS = " " } { print }')
   export WRKR_PUB_IPS=$(nova list |grep k8s | awk '{ split($12, v, "="); print v[2]}'|awk 'BEGIN { ORS = " " } { print }')

else
   WRKR_INSTANCE_IDS=""
   WRKR_PRV_IPS=()
   WRKR_PUB_IPS=()
fi

echo WRKR_PRV_HOSTS=$WRKR_PRV_IPS >> $env_variables
echo WRKR_PUB_HOSTS=$WRKR_PUB_IPS >> $env_variables
echo WRKR_INSTANCE_IDS=$WRKR_INSTANCE_IDS >> $env_variables

export PICASSO_MASTER_HOSTS=$(nova list |grep k8sdfmlopsmaster | awk '{ split($12, v, "="); print v[2]}'|awk 'BEGIN { ORS = " " } { print }')
echo PICASSO_MASTER_HOSTS=${PICASSO_MASTER_HOSTS} >> $env_variables
export PICASSO_WORKER_HOSTS=$(nova list |grep k8sdfworker | awk '{ split($12, v, "="); print v[2]}'|awk 'BEGIN { ORS = " " } { print }')
echo PICASSO_WORKER_HOSTS=${PICASSO_WORKER_HOSTS} >> $env_variables
export MLOPS_WORKER_HOSTS=$(nova list |grep k8smlopsworker | awk '{ split($12, v, "="); print v[2]}'|awk 'BEGIN { ORS = " " } { print }')
echo MLOPS_WORKER_HOSTS=${MLOPS_WORKER_HOSTS} >> $env_variables

export PICASSO_MASTER_IDS=$(nova list |grep k8sdfmlopsmaster | awk '{ split($12, v, "="); print $2}'|awk 'BEGIN { ORS = " " } { print }')
echo PICASSO_MASTER_IDS=${PICASSO_MASTER_IDS} >> $env_variables
export PICASSO_WORKER_IDS=$(nova list |grep k8sdfworker | awk '{ split($12, v, "="); print $2}'|awk 'BEGIN { ORS = " " } { print }')
echo PICASSO_WORKER_IDS=${PICASSO_WORKER_IDS} >> $env_variables
export MLOPS_WORKER_IDS=$(nova list |grep k8smlopsworker | awk '{ split($12, v, "="); print $2}'|awk 'BEGIN { ORS = " " } { print }')
echo MLOPS_WORKER_IDS=${MLOPS_WORKER_IDS} >> $env_variables

