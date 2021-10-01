#!/bin/bash

for y in `nova list |grep -v vpn | awk '{ split($12, v, "="); print v[2]}'`
do
echo "Checking ssh connectivty to instances."
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$y "echo Connected to:;hostname"
done

echo "Creating hostsfile for all instances"
nova list | grep jai | grep -v vpn|awk '{ split($12, v, "="); print v[2],$4".demo.com",$4}' > hostsfile
echo "Copying the hosts file to all instances"
for x in `nova list |grep -v vpn | awk '{ split($12, v, "="); print v[2]}'`
do
scp  -o StrictHostKeyChecking=no -i ./generated/controller.prv_key hostsfile centos@$x:/home/centos/hosts
#nohup ssh  -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$x "cat hosts|sudo tee -a /etc/hosts" &
ssh  -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@$x "cat hosts|sudo tee -a /etc/hosts >/dev/null"
done
