variable "cloud_provider" {
  description = "cloudprovider name"
  type        = string
}

variable "prefix" {
  description = "a prefix name for resources"
  type        = string
}

variable "image" {
  description = "openstack glance image for nova instances"
  type        = string
}

variable "flavor" {
  description = "openstack nova flavor for nova instances"
  type        = string
}

variable "availability_zone" {
  description = "availability zone for openstack resources"
  type        = string
}

variable "external" {
  description = "external network for access"
  type        = string
}

variable "ssh_username" {
  description = "ssh username for instances"
  type        = string
}

variable "kubernetes_version" {
  description = "desired kubernetes version for the workload cluster"
  type        = string
  default     = "v1.20.6"
}

variable "backup_enabled" {
  type    = string
  default = "false"
}

variable "letsencrypt_live" {
  default = false
}

variable "letsencrypt_mail" {
  type = string
}

variable "dns_domain" {
  type    = string
  default = "23technologies.xyz."
}

variable "flavor_worker" {
  type    = string
  default = "8C-16GB-60GB"
}

variable "flavor_worker_cpu" {
  default = "8"
  type    = string
}
variable "flavor_worker_memory" {
  default = "16Gi"
  type    = string
}
variable "flavor_worker_disk" {
  default = "60Gi"
  type    = string
}
variable "public" {
  default = "ext01"
  type    = string
}
