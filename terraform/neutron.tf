###################
# Security groups #
###################

resource "openstack_compute_secgroup_v2" "security_group_default" {
  name        = "${var.prefix}-default"
  description = "default security group"

  rule {
    self        = true
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
  rule {
    self        = true
    ip_protocol = "udp"
    from_port   = 1
    to_port     = 65535
  }
  rule {
    self        = true
    ip_protocol = "tcp"
    from_port   = 1
    to_port     = 65535
  }
}

resource "openstack_compute_secgroup_v2" "security_group_worker" {
  name        = "${var.prefix}-worker"
  description = "Give Access to kubernetes NodePort range"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 30000
    to_port     = 32767
  }
}

resource "openstack_compute_secgroup_v2" "security_group_mgmt" {
  name        = "${var.prefix}-mgmt"
  description = "mgmt security group (SSH)"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }
}

############
# Networks #
############
resource "openstack_networking_network_v2" "net_management" {
  name = "net-${var.prefix}-management"
  #  dns_domain = var.dns_domain
  #   availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_subnet_v2" "subnet_management" {
  name       = "subnet-${var.prefix}-management"
  network_id = openstack_networking_network_v2.net_management.id
  cidr       = "10.40.0.0/16"
  ip_version = 4

  allocation_pool {
    start = "10.40.255.1"
    end   = "10.40.255.254"
  }
}

resource "openstack_networking_router_v2" "router" {
  name                = var.prefix
  external_network_id = data.openstack_networking_network_v2.public.id
  #   availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet_management.id
}

data "openstack_networking_network_v2" "public" {
  name = var.public
}
