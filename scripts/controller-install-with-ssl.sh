#!/bin/bash

source "./scripts/functions.sh"
source "./scripts/variables.sh"

LOCAL_SSH_PRV_KEY_PATH="./generated/controller.prv_key"
ECP_DL_URL="https://ezmeral-platform-releases.s3.amazonaws.com/5.3.3/3047/hpe-cp-rhel-release-5.3.3-3047.bin"
ECP_OPTIONS="--skipeula --default-password admin123"
ECP_FILENAME="hpe-cp-rhel-release-5.3.bin"
INSTALL_WITH_SSL=True

echo "SSHing into Controller ${CTRL_PUB_IP}"

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PRV_IP} << ENDSSH
   set -eu

   sudo yum install -y wget

   # manually install epel due to https://stackoverflow.com/questions/62359639/unable-to-install-packages-via-yum-in-aws-errno-1-repomd-xml-does-not-match
   wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
   sudo yum install -y -q epel-release-latest-7.noarch.rpm || echo "Ignoring error installing epel"


   if [[ -e /home/centos/bd_installed ]]
   then
      echo BlueData already installed - quitting
      exit 0
   fi

   set -e # abort on error

   sudo yum -y -q install git wget
   wget -c --progress=bar -e dotbytes=1M https://dl.google.com/go/go1.13.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz

   if [[ ! -d minica ]];
   then
      git clone https://github.com/jsha/minica.git
      cd minica/
      /usr/local/go/bin/go build
      sudo mv minica /usr/local/bin
   fi

   # FIXME: Currently this requires SELINUX to be disabled so apache httpd can read the certs
   rm -rf /home/centos/${CTRL_PUB_DNS}
   cd /home/centos
   minica -domains "$CTRL_PUB_DNS,$CTRL_PRV_DNS,$GATW_PUB_DNS,$GATW_PRV_DNS,$CTRL_PUB_HOST,$CTRL_PRV_HOST,$GATW_PUB_HOST,$GATW_PRV_HOST,localhost" \
      -ip-addresses "$CTRL_PUB_IP,$CTRL_PRV_IP,$GATW_PUB_IP,$GATW_PRV_IP,127.0.0.1"

   # output the ssl details for debugging purposes
   openssl x509 -in /home/centos/${CTRL_PUB_DNS}/cert.pem -text

   echo "Checking /etc/hosts"
   cat hosts|sudo tee -a /etc/hosts

   echo "Adding Docker repo"
   sudo yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
   sudo yum -y install docker-ce-19.03.5

   echo "Adding dependancies"
   sudo yum install -y ceph-common yum-utils sos python-requests python-argparse python-boto python-requests-kerberos python-urllib3 policycoreutils-python python-dateutil \
   httpd mod_ssl mod_wsgi cyrus-sasl cyrus-sasl-gssapi cyrus-sasl-md5 krb5-workstation krb5-libs json-c libcurl chrony bind-utils bc lvm2 parted autofs psmisc rpcbind patch \
   curl wget createrepo libcgroup-tools nfs-utils python-iniparse python-ipaddr openssh-clients python-setuptools createrepo openldap-clients libxml2-devel libxslt-devel \
   dnsmasq haproxy socat rsyslog iputils selinux-policy openssl-devel python-cffi python-virtualenv container-storage-setup
   
   echo "Downloading ${ECP_DL_URL} to ${ECP_FILENAME}"

    wget -c --progress=bar -e dotbytes=10M -O ${ECP_FILENAME} "${ECP_DL_URL}"
   chmod +x ${ECP_FILENAME}

   echo "Running ECP install"

   # install ECP (Note: minica puts the cert and key in a folder named after the first DNS domain)
   if [[ "${INSTALL_WITH_SSL}" == "True" ]]; then
      ./${ECP_FILENAME} ${ECP_OPTIONS} --ssl-cert /home/centos/${CTRL_PUB_DNS}/cert.pem --ssl-priv-key /home/centos/${CTRL_PUB_DNS}/key.pem
   else
      ./${ECP_FILENAME} ${ECP_OPTIONS}
   fi

ENDSSH

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
