provider "aws" {
    region = "eu-central-1"
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr
}

resource "aws_internet_gateway" "vpn_gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-gateway"
  }
}

resource "aws_subnet" "intern" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidr, 4, 1)

  tags = {
    Name = "${var.prefix}-intern"
  }
}

resource "aws_subnet" "extern" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidr, 4, 2)

  tags = {
    Name = "${var.prefix}-extern"
  }
}


module "kubernetes" {
  source  = "scholzj/kubernetes/aws"
  version = "1.12.2"
  # insert the 9 required variables here
  aws_region    = var.availability_zone
  cluster_name  = var.prefix
  master_instance_type = var.flavor_master
  worker_instance_type = var.flavor_worker
  ssh_public_key = var.ssh_key
  ssh_access_cidr = ["0.0.0.0/0"]
  api_access_cidr = ["0.0.0.0/0"]
  min_worker_count = var.min_workers
  max_worker_count = var.max_workers
  hosted_zone = var.dns_domain
  hosted_zone_private = false

  master_subnet_id = aws_subnet.intern.id
  worker_subnet_ids = [		
      aws_subnet.intern.id,
      aws_subnet.extern.id
  ]
  
  # Tags
  tags = {
    Application = "AWS-Kubernetes"
    Type = "development"
  }

  # Tags in a different format for Auto Scaling Group
  tags2 = [
    {
      key                 = "Application"
      value               = "AWS-Kubernetes"
      propagate_at_launch = true
    }
  ]
  
  addons = [
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/storage-class.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/heapster.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/dashboard.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/external-dns.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/autoscaler.yaml"
  ]
}
