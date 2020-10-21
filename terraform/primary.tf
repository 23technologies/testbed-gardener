resource "openstack_networking_floatingip_v2" "primary_floating_ip" {
  pool       = var.public
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_floatingip_associate_v2" "primary_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.primary_floating_ip.address
  port_id     = openstack_networking_port_v2.primary_port_management.id
}

resource "openstack_networking_port_v2" "primary_port_management" {
  network_id = openstack_networking_network_v2.net_management.id
  security_group_ids = [
    openstack_compute_secgroup_v2.security_group_management.id,
    openstack_compute_secgroup_v2.security_group_primary.id
  ]

  fixed_ip {
    ip_address = "10.43.10.10"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_compute_instance_v2" "primary_server" {
  name              = "${var.prefix}-primary"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_primary
  key_pair          = openstack_compute_keypair_v2.key.name

  network { port = openstack_networking_port_v2.primary_port_management.id }

  user_data = <<-EOT
#cloud-config
package_update: true
package_upgrade: true
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
runcmd:
  - curl https://get.k3s.io | K3S_TOKEN=${var.k3s_token} INSTALL_K3S_EXEC="server --disable traefik,metrics-server" sh -
  - cp /etc/rancher/k3s/k3s.yaml /home/${var.ssh_username}/k3s.yaml
  - "chown ${var.ssh_username}: /home/${var.ssh_username}/k3s.yaml"
EOT

}
