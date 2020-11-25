resource "openstack_networking_port_v2" "main_port_management" {
  count      = var.number_of_controlplane_nodes
  network_id = openstack_networking_network_v2.net_management.id
  # the controlplane nodes get the worker-security group too becaus they forward NodePort traffic
  security_group_ids = [openstack_compute_secgroup_v2.security_group_default.id, openstack_compute_secgroup_v2.security_group_worker.id]

  fixed_ip {
    ip_address = "10.40.10.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_compute_instance_v2" "main_server" {
  count             = var.number_of_controlplane_nodes
  name              = "${var.prefix}-main-${count.index}"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_main
  key_pair          = openstack_compute_keypair_v2.key.name

  network { port = openstack_networking_port_v2.main_port_management[count.index].id }

  user_data = <<-EOT
#cloud-config
package_update: true
package_upgrade: true
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
runcmd:
  - apt -y install docker.io
  - systemctl enable docker --now
  - apt -y install docker.io
  - groupadd docker
  - usermod -aG docker ${var.ssh_username}
EOT

}
