resource "openstack_networking_port_v2" "worker_port_management" {
  count              = var.number_of_workers
  network_id         = openstack_networking_network_v2.net_management.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_default.id, openstack_compute_secgroup_v2.security_group_worker.id]

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

  depends_on = [openstack_compute_instance_v2.main_server]

  network { port = openstack_networking_port_v2.worker_port_management[count.index].id }

  user_data = <<-EOT
#cloud-config
package_update: true
package_upgrade: true
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
write_files:
  - encoding: b64
    content: ewogICJtdHUiOiAxNDAwCn0K # set mtu 1400
    owner: root:root
    path: /tmp/daemon.json
    permissions: '0644'
runcmd:
  - mkdir /etc/docker
  - mv /tmp/daemon.json /etc/docker/daemon.json
  - groupadd docker
  - usermod -aG docker ${var.ssh_username}
  - apt -y install docker.io
  - systemctl enable docker --now
EOT

}
