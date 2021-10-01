# please fill these variables or use TF_VARS_ prefix to be exported env variables
# 
openstack_username = "jaideep.joshi"
openstack_password = "" 
openstack_domain   = "HPE_Ezmeral"
openstack_project  = "3d46abc7b3de4b3cb67c4e5bc86c3fd4"
openstack_auth_url = "https://api.us-east-1.orocktech.com:13000/v3/"

private_key = "./generated/controller.prv_key"

#VPN Server Ubuntu image ID
demo-vpn-image-id = "3f0a2723-a58f-4205-881c-3acbe08a3974"

# Nodes server Image ID
hpe_node_image_id = "6b2024f7-29d8-446b-bdad-ca78ca8573a5"

# Count of ecp controllers (place holder for pri+shadow) 
#count-demo-controllers = "1"

#Vanilla K8s Cluster. Not working yet
count-k8smasters = "0"
count-k8sworkers = "0"

#DF and ML-Ops K8s Cluster
count-k8sdfmlopsmasters = "3"
count-k8sdfworkers = "5"
count-k8smlopsworkers = "3"

#External DF Cluster
count-externaldf-hosts = "0"

# Instances' flavor size
demo-vpn-flavor = "t1.small"
demo-controller-flavor = "m1.xlarge"
demo-gateway-flavor = "m1.xlarge"
demo-adserver-flavor = "m1.xlarge"
demo-rdpserver-flavor = "t1.xlarge"
demo-k8smaster-flavor = "t1.xlarge"
demo-k8sworker-flavor = "t1.xlarge"
demo-k8sdfmlopsmaster-flavor = "t1.xlarge"
demo-k8sdfworker-flavor = "t1.xlarge"
demo-k8smlopsworker-flavor = "t1.xlarge"
demo-externaldf-flavor = "t1.xlarge"

# All Resourcesi for this demo env will be prefixed to avoid clashing names
prefix = "jai-ecp"

# Name of floating IP pool
ip_pool_name = "external-floating-ips"
# ID of External Network
external_network = "external-floating-ips"

# Admin password to access hpe
# hpe_admin_password = "admin123"

# Name of custom cluster that will be created
# cluster_name = "demo"

