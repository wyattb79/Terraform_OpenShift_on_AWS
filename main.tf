terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "openshift_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.stack_name
  }
}

resource "aws_subnet" "controlplane_subnet" {
  vpc_id                  = aws_vpc.openshift_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = "true"
  tags = {
    Name = var.stack_name
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.openshift_vpc.id
  cidr_block = var.private_subnet_cidr
  tags = {
    Name = var.stack_name
  }
}

resource "aws_security_group" "control_plane_sg" {
  name        = "Login security group"
  description = "Allow login from my IP"
  vpc_id      = aws_vpc.openshift_vpc.id

  ingress {
    description = "Allow ssh from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.login_ip]
  }

  // terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Openshift Terraform Login SG"
  }
}

resource "aws_security_group" "cluster_internal_sg" {
  name        = "Cluster internal security group"
  description = "Allow all traffic between nodes"
  vpc_id      = aws_vpc.openshift_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  // terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Openshift Terraform Internal SG"
  }
}

resource "aws_internet_gateway" "cluster_igw" {
  vpc_id = aws_vpc.openshift_vpc.id

  tags = {
    Name = "OpenShift Cluster IGW"
  }
}

resource "aws_route_table" "cluster_route_table" {
  vpc_id = aws_vpc.openshift_vpc.id

  tags = {
    Name = "OpenShift Cluster Route Table"
  }
}

resource "aws_route" "cluster_route_to_internet" {
  route_table_id = aws_route_table.cluster_route_table.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cluster_igw.id
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id         = aws_subnet.private_subnet.id
  connectivity_type = "private"

  tags = {
    Name = "OpenShift NAT gw"
  }
}

resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.openshift_vpc.id

  tags = {
    Name = "Openshift Cluster Private Route Table"
  }
}

resource "aws_route" "private_route" {
  route_table_id = aws_route_table.private_subnet_route_table.id

  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "route_as" {
  subnet_id      = aws_subnet.controlplane_subnet.id
  route_table_id = aws_route_table.cluster_route_table.id
}

resource "aws_route_table_association" "private_route_as" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_subnet_route_table.id
}

data "aws_ami" "rhel8" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-8*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  // Red Hat
  owners = ["309956199498"]
}

resource "aws_instance" "control_plane" {
  ami             = data.aws_ami.rhel8.id
  instance_type   = var.control_plane_type
  count           = var.control_plane_nodes
  key_name        = var.key_name
  security_groups = [aws_security_group.control_plane_sg.id, aws_security_group.cluster_internal_sg.id]
  subnet_id       = aws_subnet.controlplane_subnet.id

  tags = {
    Name = "control_plane-${count.index}"
  }
}

resource "aws_instance" "worker_node" {
  ami             = data.aws_ami.rhel8.id
  instance_type   = var.worker_node_type
  count           = var.worker_nodes
  key_name        = var.key_name
  security_groups = [aws_security_group.cluster_internal_sg.id]
  subnet_id       = aws_subnet.private_subnet.id

  tags = {
    Name = "worker_node-${count.index}"
  }
}
