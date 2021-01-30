provider "openstack" {
  cloud = var.cloud_provider
}

terraform {
  required_version = ">= 0.14"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.35.0"
    }

    random = {
      source = "hashicorp/random"
    }

    local = {
      source = "hashicorp/local"
    }
  }
}
