resource "openstack_dns_zone_v2" "default_zone" {
  name        = join("", [var.dns_domain, "."])
  email       = "muench@23technologies.cloud"
  description = "default"
  ttl         = 30
  type        = "PRIMARY"
}
