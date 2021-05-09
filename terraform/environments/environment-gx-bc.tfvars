# a working set for gx-scs
#
prefix            = "capi"
cloud_provider    = "gx-bc"
availability_zone = "south-2"
external          = "external"
flavor            = "4C-8GB-20GB"
image             = "Ubuntu 20.04"
ssh_username      = "ubuntu"
dns_domain                = "gardener-1.23technologies.xyz"
flavor_main               = "4C-8GB-40GB"
flavor_mgmt               = "2C-2GB-20GB"
flavor_worker             = "4C-16GB-40GB"
flavor_worker_cpu         = "4"
flavor_worker_memory      = "16Gi"
flavor_worker_disk        = "40Gi"
network_availability_zone = "south-2"
network_management        = "gardener"
public                    = "external"
letsencrypt_mail          = "muench@23technologies.cloud"
letsencrypt_live          = false
backup_enabled            = "false"

