provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr
  enable_dns_hostnames = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "${var.prefix}-vpc"
  }

}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-gateway"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }


#   route {
#     cidr_block = var.cidr
#     gateway_id = aws_internet_gateway.main.id
#   }

#   route {
#     ipv6_cidr_block        = "::/0"
#     gateway_id = aws_internet_gateway.main.id
#   }

  tags = {
    Name = "${var.prefix}-routing"
  }
}

resource "aws_route_table_association" "gateway" {
  gateway_id     = aws_internet_gateway.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_main_route_table_association" "main_table" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.main.id
}


resource "aws_subnet" "intern" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidr, 4, 1)
  # ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.prefix}-intern"
  }
}

resource "aws_route_table_association" "intern" {
  subnet_id     = aws_subnet.intern.id
  route_table_id = aws_route_table.main.id
}

resource "aws_subnet" "extern" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidr, 4, 2)
  # ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 2)
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.prefix}-extern"
  }
}

resource "aws_route_table_association" "extern" {
  subnet_id     = aws_subnet.extern.id
  route_table_id = aws_route_table.main.id
}

locals {
    ssh_key_pub = "${var.ssh_key}.pub"
}


module "kubernetes" {
  source  = "scholzj/kubernetes/aws"
  version = "1.12.2"
  # insert the 9 required variables here
  aws_region    = var.region
  cluster_name  = var.prefix
  master_instance_type = var.flavor_master
  worker_instance_type = var.flavor_worker
  ssh_public_key = local.ssh_key_pub
  ssh_access_cidr = ["0.0.0.0/0"]
  api_access_cidr = ["0.0.0.0/0"]
  min_worker_count = var.min_workers
  max_worker_count = var.max_workers
  hosted_zone = var.dns_domain
  hosted_zone_private = false

  master_subnet_id = aws_subnet.extern.id
  worker_subnet_ids = [		
      aws_subnet.extern.id
#      aws_subnet.intern.id,
  ]
  
  # Tags
  tags = {
    Application = "Kubernetes-${var.prefix}"
    Type = "development"
  }

  # Tags in a different format for Auto Scaling Group
  tags2 = [
    {
      key                 = "Application"
      value               = "Kubernetes-${var.prefix}"
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

# copy kubectl config
