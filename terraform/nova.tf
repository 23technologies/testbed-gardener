resource "openstack_compute_keypair_v2" "key" {
  name = "${var.prefix}-${var.cloud_provider}"
}
