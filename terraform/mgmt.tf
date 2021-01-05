resource "openstack_networking_floatingip_v2" "mgmt_floating_ip" {
  pool       = var.public
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_port_v2" "mgmt_port_management" {
  network_id = openstack_networking_network_v2.net_management.id
  security_group_ids = [
    openstack_compute_secgroup_v2.security_group_default.id,
    openstack_compute_secgroup_v2.security_group_mgmt.id
  ]

  fixed_ip {
    ip_address = "10.40.0.10"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_networking_floatingip_associate_v2" "mgmt_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.mgmt_floating_ip.address
  port_id     = openstack_networking_port_v2.mgmt_port_management.id
}

locals {
  clouds = lookup(lookup(yamldecode(file("clouds.yaml")), "clouds"), var.cloud_provider)
  secure = lookup(lookup(yamldecode(file("secure.yaml")), "clouds"), var.cloud_provider)
}


resource "openstack_compute_instance_v2" "mgmt_server" {
  name              = "${var.prefix}-mgmt"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_mgmt
  key_pair          = openstack_compute_keypair_v2.key.name

  depends_on = [openstack_compute_instance_v2.main_server]

  network { port = openstack_networking_port_v2.mgmt_port_management.id }

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
EOT

  connection {
    host        = openstack_networking_floatingip_v2.mgmt_floating_ip.address
    private_key = openstack_compute_keypair_v2.key.private_key
    user        = var.ssh_username
  }

  provisioner "file" {
    content     = openstack_compute_keypair_v2.key.private_key
    destination = "/home/${var.ssh_username}/.ssh/id_rsa"
  }

  provisioner "file" {
    content     = templatefile("files/${var.cloud_provider}/acre.yaml.tmpl", { clouds = local.clouds, secure = local.secure, public = var.public, dns_domain = var.dns_domain, flavor_worker = var.flavor_worker, pw = random_password.gardener_password.result })
    destination = "/home/${var.ssh_username}/acre.yaml"
  }

  provisioner "file" {
    content     = templatefile("files/cloud.conf.tmpl", { clouds = local.clouds, secure = local.secure, subnet = openstack_networking_subnet_v2.subnet_management, public = data.openstack_networking_network_v2.public })
    destination = "/home/${var.ssh_username}/cloud.conf"
  }

  provisioner "file" {
    source      = "files/install_keycloak.sh"
    destination = "/home/${var.ssh_username}/install_keycloak.sh"
  }

  provisioner "file" {
    source      = "files/bootstrap.sh"
    destination = "/home/${var.ssh_username}/bootstrap.sh"
  }

  provisioner "file" {
    content = templatefile("files/cluster.yml.tmpl", { ssh_username = var.ssh_username,
      prefix        = var.prefix,
      controlplanes = openstack_compute_instance_v2.main_server,
      workers       = openstack_compute_instance_v2.worker,
      clouds        = local.clouds,
      secure        = local.secure,
      subnet        = openstack_networking_subnet_v2.subnet_management,
    public = data.openstack_networking_network_v2.public })
    destination = "/home/${var.ssh_username}/cluster.yml"
  }

  provisioner "file" {
    source      = "files/deploy.sh"
    destination = "/home/${var.ssh_username}/deploy.sh"
  }

  provisioner "file" {
    source      = "files/kubernetes-manifests.d/"
    destination = "/home/${var.ssh_username}"
  }

  provisioner "local-exec" {
    command = "sleep 180"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/bootstrap.sh"
    ]
  }
}


