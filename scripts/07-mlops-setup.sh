#!/bin/bash

set -e
set -o pipefail

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

exec > >(tee -i generated/$(basename $0).log)
exec 2>&1

CLUSTER_ID=$(hpecp k8scluster list|grep cluster|awk '{print $2}')
echo "Creating MLOPS Tenant"
TENANT_ID=$(hpecp tenant create --name "k8s-tenant-1" --description "MLOPS Example" --k8s-cluster-id $CLUSTER_ID  --tenant-type k8s --features '{ ml_project: true }' --quota-cores 1000)
hpecp tenant wait-for-status --id $TENANT_ID --status [ready] --timeout-secs 1800
echo "K8S tenant created successfully - ID: ${TENANT_ID}"
echo TENANT_ID=$TENANT_ID

TENANT_NS=$(hpecp tenant get $TENANT_ID | grep "^namespace: " | cut -d " " -f 2)
echo TENANT_NS=$TENANT_NS

ADMIN_GROUP="CN=${AD_ADMIN_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
ADMIN_ROLE=$(hpecp role list  --query "[?label.name == 'Admin'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$ADMIN_GROUP" --role-id "$ADMIN_ROLE"

MEMBER_GROUP="CN=${AD_MEMBER_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
MEMBER_ROLE=$(hpecp role list  --query "[?label.name == 'Member'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$MEMBER_GROUP" --role-id "$MEMBER_ROLE"
echo "Configured tenant with AD groups Admins=${AD_ADMIN_GROUP}... and Members=${AD_MEMBER_GROUP}..."

#echo "Setting up Gitea server"
#retry ./scripts/07a-gitea_setup.sh $TENANT_ID apply

echo "Setting up MLFLOW cluster"
retry ./scripts/07a-mlflow-cluster-create.sh $TENANT_ID

echo "Setting up Notebook"
retry ./scripts/07b-setup-notebook.sh $TENANT_ID

echo "Waiting for mlflow KD app to have state==configured"
retry ./scripts/07c-check-mlflow-configured-state.sh $TENANT_ID mlflow

echo "Retrieving minio gateway host and port"
#MINIO_HOST_AND_PORT="$(./scripts/07d-minio-get-gw-host-and-port.sh $TENANT_ID mlflow)"
#echo MINIO_HOST_AND_PORT=$MINIO_HOST_AND_PORT

echo "Creating minio bucket"
#retry ./scripts/07e-minio-create-bucket.sh "$MINIO_HOST_AND_PORT"

echo "Verifying KubeFlow"
#./scripts/07f-verify-kf.sh $TENANT_ID