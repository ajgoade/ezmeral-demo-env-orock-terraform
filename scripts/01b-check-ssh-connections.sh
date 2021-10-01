#!/bin/bash

echo "Checking ssh connectivty to instances. Please wait."

[ -e ~/.ssh/known_hosts ] && rm ~/.ssh/known_hosts 

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

for y in `nova list |grep -v vpn |grep -v adserver | awk '{ split($12, v, "="); print v[2]}'`
do
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo Connected to:;hostname"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo Kicking of yum update on:;hostname"
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "sudo yum update -y" > /dev/null 2>&1 & 
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "jobs -l" 
done

echo "Creating hostsfile for all instances"
nova list | grep $PROJECT_ID| grep -v vpn|awk '{ split($12, v, "="); print v[2],$4".demo.com",$4}' > ./generated/hostsfile

echo "Copying the hostsfile to all instances"

for x in `nova list |grep -v vpn | awk '{ split($12, v, "="); print v[2]}'`
do
scp  -o StrictHostKeyChecking=no -i ./generated/controller.prv_key ./generated/hostsfile centos@$x:/home/centos/hosts
#nohup ssh  -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$x "cat hosts|sudo tee -a /etc/hosts" &
ssh  -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$x "cat hosts|sudo tee -a /etc/hosts >/dev/null"
done
