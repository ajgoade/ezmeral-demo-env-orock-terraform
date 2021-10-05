source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

WORKER_COUNT=$(nova list|grep k8s|wc -l)

if [[ "$WORKER_COUNT" != "0" ]]; then
   export WRKR_INSTANCE_IDS=$(nova list |grep k8s | awk '{ split($12, v, "="); print $2}'|awk 'BEGIN { ORS = " " } { print }')
   export WRKR_PRV_IPS=$(nova list |grep k8s | awk '{ split($12, v, "="); print v[2]}'|awk 'BEGIN { ORS = " " } { print }')
   export WRKR_PUB_IPS=$(nova list |grep k8s | awk '{ split($12, v, "="); print v[2]}'|awk 'BEGIN { ORS = " " } { print }')

else
   WRKR_INSTANCE_IDS=""
   WRKR_PRV_IPS=()
   WRKR_PUB_IPS=()
fi

for WRKR in `echo $WRKR_PUB_IPS|fmt -1`; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
        ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "cat >> /home/centos/.ssh/authorized_keys"
done

# test passwordless SSH connection from Controller to Workers
for WRKR in `echo $WRKR_PRV_IPS|fmt -1`; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
        echo CONTROLLER ${CTRL_PRV_IP} connecting to K8S HOST ${WRKR}...
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T centos@${WRKR} "echo Connected!"
ENDSSH
done