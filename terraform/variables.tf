variable "cloud_provider" {
  default = "gx-scs"
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

variable "flavor_mgmt" {
  default = "2C-2GB-20GB"
  type    = string
}

variable "number_of_workers" {
  default = 4
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

variable "k3s_token" {
  default = "11111111-1111-1111-1111-111111111111"
  type    = string
}

variable "ssh_username" {
  default = "ubuntu"
  type    = string
}
