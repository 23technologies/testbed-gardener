# a working set for Citycloud
#
prefix            = "capi"
cloud_provider    = "gx-citycloud"
availability_zone = "nova"
external          = "ext-net"
flavor            = "2C-6GB-20GB"
image             = "Ubuntu 20.04 Focal Fossa 20200423"
ssh_username      = "ubuntu"

dns_domain                = "gardener-citycloud.23technologies.xyz"
flavor_main               = "4C-8GB-50GB"
flavor_mgmt               = "2C-6GB-20GB"
flavor_worker             = "4C-16GB-50GB"
flavor_worker_cpu         = "4"
flavor_worker_memory      = "16Gi"
flavor_worker_disk        = "40Gi"
network_availability_zone = "south-2"
network_management        = "gardener"
public                    = "external"
letsencrypt_mail          = "muench@23technologies.cloud"
letsencrypt_live          = false
backup_enabled            = "false"

