#!/bin/bash

tput setaf 2
echo "Installing/Configuring ECP Controller"
tput sgr0

set -e # abort on error
set -u # abort on undefined variable
set -o pipefail

#SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

#############################
#Install ECP Controller
#############################
for y in `nova list |grep controller | awk '{ split($12, v, "="); print v[2]}'`
do
echo "Install ECP Controller packages on"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "hostname" 
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install -y deltarpm" 
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install -y wget git" 
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo sed -i --follow-symlinks 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install -y -q epel-release-latest-7.noarch.rpm"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "wget -c --progress=bar -e dotbytes=1M https://ezmeral-platform-releases.s3.amazonaws.com/5.3.3/3047/hpe-cp-rhel-release-5.3.3-3047.bin"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "chmod +x hpe-cp-rhel-release-5.3.3-3047.bin"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "cat hosts|sudo tee -a /etc/hosts"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum -y install docker-ce-19.03.5"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install -y ceph-common yum-utils sos python-requests python-argparse python-boto python-requests-kerberos python-urllib3 policycoreutils-python python-dateutil httpd mod_ssl mod_wsgi cyrus-sasl cyrus-sasl-gssapi cyrus-sasl-md5 krb5-workstation krb5-libs json-c libcurl chrony bind-utils bc lvm2 parted autofs psmisc rpcbind patch curl wget createrepo libcgroup-tools nfs-utils python-iniparse python-ipaddr openssh-clients python-setuptools createrepo openldap-clients libxml2-devel libxslt-devel dnsmasq haproxy socat rsyslog iputils selinux-policy openssl-devel python-cffi python-virtualenv container-storage-setup"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "./hpe-cp-rhel-release-5.3.3-3047.bin --default-password admin123 --skipeula"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y << ENDSSH
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
done

tput setaf 2
echo "Create HPECP conf file"
tput sgr0
./scripts/03a-create-enhpecp-conf.sh

tput setaf 2
echo "Configuring Controller to use AD/LDAP server"
tput sgr0
./scripts/03b-configure-global-active-directory.sh
