resource "openstack_networking_floatingip_v2" "seed_floating_ip" {
  pool       = var.public
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_port_v2" "seed_port_management" {
  network_id = openstack_networking_network_v2.net_management.id
  security_group_ids = [
    openstack_compute_secgroup_v2.security_group_management.id,
    openstack_compute_secgroup_v2.security_group_seed.id
  ]

  fixed_ip {
    ip_address = "10.43.0.10"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_networking_floatingip_associate_v2" "seed_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.seed_floating_ip.address
  port_id     = openstack_networking_port_v2.seed_port_management.id
}

resource "openstack_compute_instance_v2" "seed_server" {
  name              = "${var.prefix}-seed"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_seed
  key_pair          = openstack_compute_keypair_v2.key.name

  depends_on = [openstack_compute_instance_v2.primary_server]

  network { port = openstack_networking_port_v2.seed_port_management.id }

  user_data = <<-EOT
#cloud-config
package_update: true
package_upgrade: true
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
runcmd:
  - groupadd docker
  - usermod -aG docker ${var.ssh_username}
EOT

  connection {
    host        = openstack_networking_floatingip_v2.seed_floating_ip.address
    private_key = openstack_compute_keypair_v2.key.private_key
    user        = var.ssh_username
  }

  provisioner "file" {
    content     = openstack_compute_keypair_v2.key.private_key
    destination = "/home/${var.ssh_username}/.ssh/id_rsa"
  }

  provisioner "file" {
    source      = "files/${var.cloud_provider}/acre.yaml"
    destination = "/home/${var.ssh_username}/acre.yaml"
  }

  provisioner "file" {
    source      = "files/${var.cloud_provider}/credentials.yaml"
    destination = "/home/${var.ssh_username}/credentials.yaml"
  }

  provisioner "file" {
    source      = "files/bootstrap.sh"
    destination = "/home/${var.ssh_username}/bootstrap.sh"
  }

  provisioner "file" {
    source      = "files/deploy.sh"
    destination = "/home/${var.ssh_username}/deploy.sh"
  }

  provisioner "local-exec" {
    command = "sleep 120"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/bootstrap.sh"
    ]
  }
}