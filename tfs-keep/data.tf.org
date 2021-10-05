# Retrieving external network information.
data "openstack_networking_network_v2" "external_network" {
  name = var.external_network
}

# Cloud-init file for Worker instances. 
# Installs the required packages, Imports SSH key, and registers node to the cluster based on its roles
data "template_file" "cloud-config-worker" {
  template = file("./configs/worker-cloud-init.yaml")
  vars = {
    ssh_public_key = openstack_compute_keypair_v2.demo_keypair.public_key
  }
  # depends_on = [hpe_cluster.demo]
}

# Cloud-init file for Master instances. 
# Installs the required packages, Imports SSH key, and registers node to the cluster based on its roles
data "template_file" "cloud-config-master" {
  template = file("./configs/master-cloud-init.yaml")
  vars = {
    ssh_public_key = openstack_compute_keypair_v2.demo_keypair.public_key
  }
  # depends_on = [hpe_cluster.demo]
}

# Cloud-init file for hpe server instance. 
# Installs the required packages, Imports SSH key, and Runs hpe docker container as systemd.service 
data "template_file" "cloud-config-server" {
  template = file("./configs/server-cloud-init.yaml")
  vars = {
    ssh_public_key = openstack_compute_keypair_v2.demo_keypair.public_key
  }
}
