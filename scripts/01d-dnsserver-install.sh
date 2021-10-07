#!/bin/bash

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

exec > >(tee -i generated/$(basename $0).log)
exec 2>&1

#############################
#Install DNS Server
#############################
y=$(nova list |grep dnsserver | awk '{ split($12, v, "="); print v[2]}') 
echo "Setting up DNS Server $y"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "hostname"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo sed -i --follow-symlinks 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo yum install -y -q epel-release-latest-7.noarch.rpm --nogpgcheck"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo yum -y install bind-utils"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo yum -y install dnsmasq"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak" 
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo listen-address=::1,127.0.0.1,$y >> dnsmasq.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo domain=demo.com >> dnsmasq.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo address=/demo.com/127.0.0.1 >> dnsmasq.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo address=/demo.com/$y >> dnsmasq.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "cat dnsmasq.conf|sudo tee -a /etc/dnsmasq.conf" 
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo mv /etc/resolv.conf /etc/resolv.conf.bak" 
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo nameserver $y >> resolv.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo nameserver 1.1.1.1 >> resolv.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "cat resolv.conf|sudo tee -a /etc/resolv.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo systemctl restart dnsmasq"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo systemctl status dnsmasq"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo dnsmasq --test"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "nslookup $CTRL_PRV_HOST"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo DNSmasq setup complete"
# Install KUBECTL
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "echo Installing kubectl"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "chmod +x ./kubectl"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo mv ./kubectl /usr/local/bin/kubectl"
# Install HELM
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "echo Installing helm"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "chmod 700 get_helm.sh"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "./get_helm.sh"
 # Install HPECP   
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "echo Installing pip3/hpecp"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo yum install python3-pip -y"
ssh -o StrictHostKeyChecking=no -i $LOCAL_SSH_PRV_KEY_PATH centos@$y "sudo pip3 install --upgrade --user hpecp"

tput setaf 2
echo "DNS Server Ready"
tput sgr0