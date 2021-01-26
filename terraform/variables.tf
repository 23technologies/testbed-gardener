variable "cloud_provider" {
  default = "default"
  type    = string
}

variable "prefix" {
  default = "garden-cluster"
  type    = string
}

variable "dns_domain" {
  default = "23technologies.xyz."
  type    = string
}

variable "image" {
  default = "Ubuntu 20.04"
  type    = string
}

variable "flavor_main" {
  default = "4C-8GB-60GB"
  type    = string
}

variable "flavor_worker" {
  default = "4C-8GB-60GB"
  type    = string
}

variable "flavor_worker_cpu" {
  default = "4"
  type    = string
}

variable "flavor_worker_memory" {
  default = "8Gi"
  type    = string
}

variable "flavor_worker_disk" {
  default = "60Gi"
  type    = string
}

variable "flavor_mgmt" {
  default = "2C-2GB-20GB"
  type    = string
}

variable "number_of_workers" {
  default = 3
  type    = number
}

variable "number_of_controlplane_nodes" {
  default = 3
  type    = number
}

variable "availability_zone" {
  default = "nova"
  type    = string
}

variable "network_availability_zone" {
  default = "nova"
  type    = string
}

variable "network_management" {
  default = "gardener"
  type    = string
}

variable "public" {
  default = "ext01"
  type    = string
}

variable "port_security_enabled" {
  default = false
  type    = bool
}

variable "ssh_username" {
  default = "ubuntu"
  type    = string
}

variable "letsencrypt_live" {
  default = false
}

variable "letsencrypt_mail" {
  type = string
}

variable "backup_enabled" {
  default = "false"
  type    = string
}

