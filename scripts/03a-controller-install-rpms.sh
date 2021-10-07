#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable
set -o pipefail

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

for y in `nova list |grep controller | awk '{ split($12, v, "="); print v[2]}'`
do
echo "Installing RPMS on Controller"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "hostname" 
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install -y deltarpm" 
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install -y wget git" 
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo sed -i --follow-symlinks 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install -y -q epel-release-latest-7.noarch.rpm"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "cat hosts|sudo tee -a /etc/hosts"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum -y install docker-ce-19.03.5"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "wget -c --progress=bar -e dotbytes=1M https://dl.google.com/go/go1.13.linux-amd64.tar.gz"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "git clone https://github.com/jsha/minica.git"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "cd minica;/usr/local/go/bin/go build"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo rm -rf /usr/local/bin/minica" 
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo mv /home/centos/minica/minica /usr/local/bin"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "which minica"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y minica -domains "$CTRL_PUB_DNS,$CTRL_PRV_DNS,$GATW_PUB_DNS,$GATW_PRV_DNS,$CTRL_PUB_HOST,$CTRL_PRV_HOST,$GATW_PUB_HOST,$GATW_PRV_HOST,localhost" -ip-addresses "$CTRL_PUB_IP,$CTRL_PRV_IP,$GATW_PUB_IP,$GATW_PRV_IP,127.0.0.1"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "openssl x509 -in /home/centos/minica.pem -text"    
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install -y ceph-common yum-utils sos python-requests python-argparse python-boto python-requests-kerberos python-urllib3 policycoreutils-python python-dateutil httpd mod_ssl mod_wsgi cyrus-sasl cyrus-sasl-gssapi cyrus-sasl-md5 krb5-workstation krb5-libs json-c libcurl chrony bind-utils bc lvm2 parted autofs psmisc rpcbind patch curl wget createrepo libcgroup-tools nfs-utils python-iniparse python-ipaddr openssh-clients python-setuptools createrepo openldap-clients libxml2-devel libxslt-devel dnsmasq haproxy socat rsyslog iputils selinux-policy openssl-devel python-cffi python-virtualenv container-storage-setup"

ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "echo Rebooting Controller"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "nohup sudo reboot </dev/null &"
done

sleep 10
echo 'Waiting for Controller to Reboot '
while ! nc -w5 -z ${CTRL_PUB_IP} 22; do printf "." -n ; done;
echo 'Controller has Rebooted'
