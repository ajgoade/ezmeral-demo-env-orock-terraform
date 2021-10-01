##################################
# Creating ecp controller volumes
#################################

resource "openstack_blockstorage_volume_v3" "demo-controller-sda" {
  name        = "${var.prefix}-demo-controller-sda"
  size        = 301
  image_id    = var.hpe_node_image_id
  metadata = {
    User = var.openstack_username
  }
}
resource "openstack_blockstorage_volume_v3" "demo-controller-sdb" {
  name        = "${var.prefix}-demo-controller-sdb"
  size        = 501
  metadata = {
    User = var.openstack_username
  }
}
resource "openstack_blockstorage_volume_v3" "demo-controller-sdc" {
  name        = "${var.prefix}-demo-controller-sdc"
  size        = 501
  metadata = {
    User = var.openstack_username
  }
}

##################################
# Creating ecp controller instance
#################################
resource "openstack_compute_instance_v2" "demo-controller" {
  #count          = var.count-demo-controllers
  #name            = "${var.prefix}-demo-controller-${count.index + 1}"
  count           = "1"
  name            = "${var.prefix}-demo-controller"
  flavor_name     = var.demo-controller-flavor
  key_pair        = openstack_compute_keypair_v2.demo-keypair.name
  security_groups = [openstack_networking_secgroup_v2.demo-secgroup.name]
  #user_data       = data.template_file.cloud-config-controller.rendered
  metadata = {
    User = var.openstack_username
  }

  # Booting from volumes, as someyy cloud-providers do not allow booting from image
  block_device {

    uuid                  = "${openstack_blockstorage_volume_v3.demo-controller-sda.id}"
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  
  # Add more disks
  block_device {

    uuid                  = "${openstack_blockstorage_volume_v3.demo-controller-sdb.id}"
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = true
  }
  
  block_device {

    uuid                  = "${openstack_blockstorage_volume_v3.demo-controller-sdc.id}"
    source_type           = "volume"
    boot_index            = 2
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = openstack_networking_network_v2.demo-network.name
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }

  depends_on = [openstack_compute_keypair_v2.demo-keypair, openstack_networking_subnet_v2.demo-subnet]
}

