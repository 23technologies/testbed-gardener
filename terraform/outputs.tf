output "mgmt_address" {
  value     = openstack_networking_floatingip_v2.mgmt_floating_ip.address
  sensitive = false
}

output "gardener_password" {
  value     = random_password.gardener_password.result
  sensitive = false
}

resource "local_file" "MGMT_ADDRESS" {
  filename        = ".MGMT_ADDRESS.${var.cloud_provider}"
  file_permission = "0644"
  content         = "MGMT_ADDRESS=${openstack_networking_floatingip_v2.mgmt_floating_ip.address}\n"
}
