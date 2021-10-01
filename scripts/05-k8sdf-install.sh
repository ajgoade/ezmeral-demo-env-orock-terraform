#!/bin/bash
################################################################################
#
# Picasso setup
#
################################################################################

# select the IP addresses of the k8s hosts
MASTER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $MASTER_HOSTS_INDEX)
PICASSO_WORKER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $PICASSO_WORKER_HOSTS_INDEX)
MLOPS_WORKER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $MLOPS_WORKER_HOSTS_INDEX)

# Add ECP workers without tags
./bin/experimental/03_k8sworkers_add.sh $MASTER_HOSTS &
MASTER_HOSTS_ADD_PID=$!

# Add ECP workers with picasso tags
./bin/experimental/03_k8sworkers_add_with_picasso_tag.sh $PICASSO_WORKER_HOSTS &
WORKER_DF_HOSTS_ADD_PID=$!

# Add ECP workers without picasso tags
./bin/experimental/03_k8sworkers_add.sh $MLOPS_WORKER_HOSTS &
WORKER_NON_DF_HOSTS_ADD_PID=$!

wait $MASTER_HOSTS_ADD_PID
wait $WORKER_DF_HOSTS_ADD_PID
wait $WORKER_NON_DF_HOSTS_ADD_PID


QUERY="[*] | @[?contains('${MASTER_HOSTS}', ipaddr)] | [*][_links.self.href] | [] | sort(@)"
MASTER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')
echo MASTER_HOSTS=$MASTER_HOSTS
echo MASTER_IDS=$MASTER_IDS

QUERY="[*] | @[?contains('${PICASSO_WORKER_HOSTS}', ipaddr)] | [*][_links.self.href] | [] | sort(@)"
PICASSO_WORKER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')
echo PICASSO_WORKER_HOSTS=$PICASSO_WORKER_HOSTS
echo PICASSO_WORKER_IDS=$PICASSO_WORKER_IDS

QUERY="[*] | @[?contains('${MLOPS_WORKER_HOSTS}', ipaddr)] | [*][_links.self.href] | [] | sort(@)"
MLOPS_WORKER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')
echo MLOPS_WORKER_HOSTS=$MLOPS_WORKER_HOSTS
echo MLOPS_WORKER_IDS=$MLOPS_WORKER_IDS

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 20 --output text)

AD_SERVER_PRIVATE_IP=$(terraform output ad_server_private_ip)

K8S_HOST_CONFIG="$(echo $MASTER_IDS | sed 's/ /:master,/g'):master,$(echo $PICASSO_WORKER_IDS $MLOPS_WORKER_IDS | sed 's/ /:worker,/g'):worker"
echo K8S_HOST_CONFIG=$K8S_HOST_CONFIG

EXTERNAL_GROUPS=$(echo '["CN=AD_ADMIN_GROUP,CN=Users,DC=samdom,DC=example,DC=com","CN=AD_MEMBER_GROUP,CN=Users,DC=samdom,DC=example,DC=com"]' \
    | sed s/AD_ADMIN_GROUP/${AD_ADMIN_GROUP}/g \
    | sed s/AD_MEMBER_GROUP/${AD_MEMBER_GROUP}/g)

echo "Creating k8s cluster with version ${K8S_VERSION}"
CLUSTER_ID=$(hpecp k8scluster create \
   --name dfcluster \
   --k8s-version $K8S_VERSION \
   --k8shosts-config "$K8S_HOST_CONFIG" \
   --addons '["kubeflow","picasso-compute"]' \
   --ext_id_svr_bind_pwd "5ambaPwd@" \
   --ext_id_svr_user_attribute "sAMAccountName" \
   --ext_id_svr_bind_type "search_bind" \
   --ext_id_svr_bind_dn "cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com" \
   --ext_id_svr_host "${AD_SERVER_PRIVATE_IP}" \
   --ext_id_svr_group_attribute "member" \
   --ext_id_svr_security_protocol "ldaps" \
   --ext_id_svr_base_dn "CN=Users,DC=samdom,DC=example,DC=com" \
   --ext_id_svr_verify_peer false \
   --ext_id_svr_type "Active Directory" \
   --ext_id_svr_port 636 \
   --external-groups "$EXTERNAL_GROUPS" \
   --datafabric true \
   --datafabric-name=dfdemo)
   
echo CLUSTER_ID=$CLUSTER_ID

echo CONTROLLER URL: $(terraform output controller_public_url)

date
echo "Waiting up to 1 hour for status == error|ready"
hpecp k8scluster wait-for-status '[error,ready]' --id $CLUSTER_ID --timeout-secs 3600
date

hpecp k8scluster list

hpecp config get | grep  bds_global_

if hpecp k8scluster list | grep ready
then
     ./bin/register_picasso.sh $CLUSTER_ID
else
     set +e
     THE_DATE=$(date +"%Y-%m-%dT%H:%M:%S%z")
     ./bin/ssh_controller.sh sudo tar czf - /var/log/bluedata/ > ${THE_DATE}-controller-logs.tar.gz
     
     for i in "${!WRKR_PUB_IPS[@]}"; do
       ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${WRKR_PUB_IPS[$i]} sudo tar czf - /var/log/bluedata/ > ${THE_DATE}-${WRKR_PUB_IPS[$i]}-logs.tar.gz
     done
     exit 1
fi