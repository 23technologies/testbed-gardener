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
    private_key = file(".id_rsa.${var.cloud_provider}")
    user        = var.ssh_username
  }

  provisioner "file" {
    content     = file(".id_rsa.${var.cloud_provider}")
    destination = "/home/${var.ssh_username}/.ssh/id_rsa"
  }

  provisioner "file" {
    content     = templatefile("files/acre.yaml.tmpl", { image = var.image, backup_enabled = var.backup_enabled, letsencrypt_live = var.letsencrypt_live, letsencrypt_mail = var.letsencrypt_mail, cloud_provider = var.cloud_provider, clouds = local.clouds, secure = local.secure, public = var.public, dns_domain = var.dns_domain, availability_zone = var.availability_zone, flavor_worker = var.flavor_worker, flavor_worker_cpu = var.flavor_worker_cpu, flavor_worker_memory = var.flavor_worker_memory, flavor_worker_disk = var.flavor_worker_disk, pw = random_password.gardener_password.result })
    destination = "/home/${var.ssh_username}/acre.yaml"
  }

  provisioner "file" {
    content     = templatefile("files/cloud.conf.tmpl", { clouds = local.clouds, secure = local.secure, subnet = openstack_networking_subnet_v2.subnet_management, public = data.openstack_networking_network_v2.public })
    destination = "/home/${var.ssh_username}/cloud.conf"
  }

  provisioner "file" {
    content     = templatefile("files/demo-shoot.yaml.tmpl", { flavor_worker = var.flavor_worker, availability_zone = var.availability_zone, clouds = local.clouds })
    destination = "/home/${var.ssh_username}/demo-shoot.yaml"
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
    content = templatefile("files/node_readyness.sh.tmpl", { ssh_username = var.ssh_username,
      prefix        = var.prefix,
      controlplanes = openstack_compute_instance_v2.main_server,
      workers       = openstack_compute_instance_v2.worker,
      clouds        = local.clouds,
      secure        = local.secure,
      subnet        = openstack_networking_subnet_v2.subnet_management,
    public = data.openstack_networking_network_v2.public })
    destination = "/home/${var.ssh_username}/node_readyness.sh"
  }

  provisioner "file" {
    source      = "files/wait.sh"
    destination = "/home/${var.ssh_username}/wait.sh"
  }

  provisioner "file" {
    source      = "files/deploy.sh"
    destination = "/home/${var.ssh_username}/deploy.sh"
  }

  provisioner "file" {
    source      = "files/kubernetes-manifests.d/"
    destination = "/home/${var.ssh_username}"
  }

  provisioner "file" {
    source      = "files/patch_dashboard.sh"
    destination = "/home/${var.ssh_username}/patch_dashboard.sh"
  }

  provisioner "file" {
    source      = "files/create_shoot.sh"
    destination = "/home/${var.ssh_username}/create_shoot.sh"
  }

  provisioner "file" {
    source      = "files/install_demo_app.sh"
    destination = "/home/${var.ssh_username}/install_demo_app.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/wait.sh"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/bootstrap.sh"
    ]
  }
}
