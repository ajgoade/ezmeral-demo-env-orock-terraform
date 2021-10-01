#!/bin/bash
y=192.168.206.55
ssh -o StrictHostKeyChecking=no centos@$y << ENDSSH
   set -e
   set -u
   # do initial configuration
   KERB_OPTION="-k no"
   LOCAL_TENANT_STORAGE="--no-local-tenant-storage"
   LOCAL_FS_TYPE=""
   WORKER_LIST=""
   CLUSTER_IP=""
   HA_OPTION=""
   PROXY_LIST=""
   FLOATING_IP="--routable no"
   DOMAIN_NAME="demo.ezmeral"
   CONTROLLER_IP="-c ${y}"
   CUSTOM_INSTALL_NAME="--cin demo-hpecp"
   echo "*************************************************************************************"
   echo "The next step can take 10 mins or more to run without any output - please be patient."
   echo "*************************************************************************************"
   #
   # WARNING: This script is an internal API and is not supported being used directly by users
   #
   /opt/bluedata/common-install/scripts/start_install.py \$CONTROLLER_IP \
      \$WORKER_LIST \$PROXY_LIST \$KERB_OPTION \$HA_OPTION \
      \$FLOATING_IP -t 60 -s docker -d \$DOMAIN_NAME \$CUSTOM_INSTALL_NAME \$LOCAL_TENANT_STORAGE
ENDSSH
ssh -o StrictHostKeyChecking=no centos@$y << ENDSSH
   set -eu
   # install application workbench
   sudo yum install -y -q epel-release
   sudo yum install -y -q python-pip
   # sudo pip install --upgrade pip
   # sudo pip install --upgrade setuptools
   # sudo pip install --upgrade bdworkbench

   touch /home/centos/bd_installed
ENDSSH

