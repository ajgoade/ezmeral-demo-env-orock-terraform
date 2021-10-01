#!/bin/bash
for x in `openstack server list|grep vpn|awk '{print $9}'`
do 
echo "Getting client.ovpn from VPN Server"
scp  -o StrictHostKeyChecking=no -i ./generated/controller.prv_key ubuntu@$x:/home/ubuntu/client.ovpn .
done
echo "Starting openvpn on local Mac"
sudo brew services restart openvpn
export PATH=$(brew --prefix openvpn)/sbin:$PATH
sudo openvpn --config client.ovpn > openvpn-start.log 2>&1 &
