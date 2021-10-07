#!/bin/bash

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

exec > >(tee -i generated/$(basename $0).log)
exec 2>&1

tput setaf 2
echo "Setup nameserver on all instances"
tput sgr0

#Copy resolv.conf from  DNS Server -> Workers
#

for WRKR in `nova list |grep k8s | awk '{ split($12, v, "="); print v[2]}'`; do 
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$WRKR "sudo yum install -y bind-utils" 
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$WRKR "sudo mv /etc/resolv.conf /etc/resolv.conf.bak" 
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$WRKR "echo nameserver $DNSSRVR_PRV_IP >> resolv.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$WRKR "echo nameserver 1.1.1.1 >> resolv.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$WRKR "cat resolv.conf|sudo tee -a /etc/resolv.conf"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$WRKR "echo $WRKR configured with DNS"
done

for WRKR in `nova list |grep k8s | awk '{ split($12, v, "="); print v[2]}'`; do 
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$WRKR "Resolving Gateway hostname from $WRKR"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$WRKR "nslookup $GATW_PRV_HOST" 
done

set -u

tput setaf 2
echo "DNS Setup Complete"
tput sgr0