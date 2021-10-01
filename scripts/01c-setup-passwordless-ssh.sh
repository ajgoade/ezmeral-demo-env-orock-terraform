#!/bin/bash

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

#LOCAL_SSH_PRV_KEY_PATH="./generated/controller.prv_key"

###############################################################################
# Test SSH connectivity to instances from local machine
###############################################################################

#ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} 'echo CONTROLLER: $(hostname)'
#ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${GATW_PUB_IP} 'echo GATEWAY: $(hostname)'

#for WRKR in ${WRKR_PUB_IPS[@]}; do 
#   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} 'echo WORKER: $(hostname)'
#done

###############################################################################
# Setup SSH keys for passwordless SSH
###############################################################################

cat generated/controller.prv_key | \
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat > ~/.ssh/id_rsa"

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "chmod 600 ~/.ssh/id_rsa"

cat generated/controller.pub_key | \
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat > ~/.ssh/id_rsa.pub"

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "chmod 600 ~/.ssh/id_rsa.pub"
   

# if ssh key doesn't exist on controller EC instance then create one
# ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
# if [ -f ~/.ssh/id_rsa ]
# then
#    echo CONTROLLER: Found existing ~/.ssh/id.rsa so moving on...
# else
#    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
#    echo CONTROLLER: Created ~/.ssh/id_rsa
# fi

# # BlueData controller installer requires this - TODO only add if it doesn't already exist
# cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
# ENDSSH

#
# Controller -> Gateway
#

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to the Gateway
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
  ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${GATW_PUB_IP} "cat >> /home/centos/.ssh/authorized_keys" 

# test passwordless SSH connection from Controller to Gateway
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
echo CONTROLLER ${CTRL_PRV_IP} connecting to GATEWAY ${GATW_PRV_IP}...
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T centos@${GATW_PRV_IP} "echo Controller connected to Gateway!"
ENDSSH

#
# Controller -> Workers
#

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to each Worker
set +u
for WRKR in ${WRKR_PUB_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
        ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "cat >> /home/centos/.ssh/authorized_keys"
done

# test passwordless SSH connection from Controller to Workers
for WRKR in ${WRKR_PRV_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
        echo CONTROLLER: Connecting to WORKER ${WRKR}...
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T centos@${WRKR} "echo Connected!"
ENDSSH
done
set -u

