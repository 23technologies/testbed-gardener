###################
# Security groups #
###################

resource "openstack_compute_secgroup_v2" "security_group_primary" {
  name        = "${var.prefix}-primary"
  description = "primary security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 80
    to_port     = 80
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 443
    to_port     = 443
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 6443
    to_port     = 6443
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
}

resource "openstack_compute_secgroup_v2" "security_group_seed" {
  name        = "${var.prefix}-seed"
  description = "seed security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
}

resource "openstack_compute_secgroup_v2" "security_group_management" {
  name        = "${var.prefix}-management"
  description = "management security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "udp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
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

# data "openstack_networking_network_v2" "net_management" {
#   name = var.network_management
# }

# data "openstack_networking_subnet_v2" "subnet_management" {
#   name = var.network_management
# }
