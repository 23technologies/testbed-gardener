resource "openstack_networking_port_v2" "worker_port_management" {
  count              = var.number_of_workers
  network_id         = openstack_networking_network_v2.net_management.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_management.id]

  fixed_ip {
    ip_address = "10.40.20.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count             = var.number_of_workers
  name              = "${var.prefix}-worker-${count.index}"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_worker
  key_pair          = openstack_compute_keypair_v2.key.name

  depends_on = [openstack_compute_instance_v2.master_server]

  network { port = openstack_networking_port_v2.worker_port_management[count.index].id }

  user_data = <<-EOT
#cloud-config
package_update: true
package_upgrade: true
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
runcmd:
  - curl https://get.k3s.io | K3S_TOKEN=${var.k3s_token} K3S_URL=https://garden-cluster-master:6443 INSTALL_K3S_EXEC="agent" sh -
EOT
}
