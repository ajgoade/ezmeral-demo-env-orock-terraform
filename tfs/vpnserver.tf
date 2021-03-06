# Allocating public Ip addresses for ecp controller
resource "openstack_networking_floatingip_v2" "demo-vpn-ip" {
  pool = var.ip_pool_name
}

# Attaching Floating IP to ecp controller
resource "openstack_compute_floatingip_associate_v2" "demo-vpn_ip-attach" {
  floating_ip = openstack_networking_floatingip_v2.demo-vpn-ip.address
  instance_id = openstack_compute_instance_v2.demo-vpn[0].id
  depends_on  = [openstack_compute_instance_v2.demo-vpn]
}

resource "openstack_blockstorage_volume_v3" "demo-vpnserver-sda" {
  name        = "${var.prefix}-demo-vpnserver-sda"
  size        = 51
  image_id    = var.demo-vpn-image-id
  metadata = {
    User = var.openstack_username
  }
}


##################################
# Creating vpn instance
#################################
resource "openstack_compute_instance_v2" "demo-vpn" {
  count           = "1"
  name            = "${var.prefix}-demo-vpn-server"
  flavor_name     = var.demo-vpn-flavor
  key_pair        = openstack_compute_keypair_v2.demo-keypair.name
  security_groups = [openstack_networking_secgroup_v2.demo-secgroup.name]
  metadata = {
    User = var.openstack_username
  }
 
  # Booting from volumes, as someyy cloud-providers do not allow booting from image
  block_device {

    uuid                  = "${openstack_blockstorage_volume_v3.demo-vpnserver-sda.id}"
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = openstack_networking_network_v2.demo-network.name
  }

#  depends_on = [openstack_compute_keypair_v2.demo-keypair, openstack_networking_subnet_v2.demo-subnet, openstack_networking_floatingip_v2.demo-vpn-ip]
}

resource "null_resource" "provision_vpnserver" {
  depends_on = [openstack_compute_floatingip_associate_v2.demo-vpn_ip-attach]
    connection {
      type          = "ssh"
      user          = "ubuntu"
      host          = openstack_networking_floatingip_v2.demo-vpn-ip.address
      private_key   = file("./id_rsa")
      #private_key   = var.private_key
      #private_key   = file("./controller.prv_key") 
      agent         = false
    }
  provisioner "remote-exec" {
    inline = [
      <<EOT
      sudo cd /root
      sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
      sudo curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
      sudo chmod +x openvpn-install.sh
      sudo DEBIAN_FRONTEND=noninteractive AUTO_INSTALL=y ./openvpn-install.sh
      sudo cp /home/ubuntu/client.ovpn /tmp/client.ovpn
      EOT
    ]
 }
# provisioner "file" {
# source      = "/home/ubuntu/client.ovpn"
# destination = "~/client.ovpn"
#   
#  connection {
#     type          = "ssh"
#     user          = "ubuntu"
#     host          = openstack_networking_floatingip_v2.demo-vpn-ip.address
#     private_key   = file("./id_rsa")
#     #private_key   = var.private_key
#     #private_key   = file("./controller.prv_key")
#     agent         = false
#   }
#}
}
