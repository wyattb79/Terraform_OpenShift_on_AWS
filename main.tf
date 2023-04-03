terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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

resource "aws_subnet" "openshift_subnet" {
  vpc_id = aws_vpc.openshift_vpc.id
  cidr_block = var.subnet_cidr
  tags = {
    Name = var.stack_name
  }
}

resource "aws_security_group" "login_sg" {
  name = "Login security group"
  description = "Allow login from my IP"
  vpc_id = aws_vpc.openshift_vpc.id

  ingress {
    description = "Allow ssh from my IP"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.login_ip]
  }

  // terraform removes the default rule
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "Openshift Terraform Login SG"
  }
}

resource "aws_security_group" "cluster_internal_sg" {
  name = "Cluster internal security group"
  description = "Allow all traffic between nodes"
  vpc_id = aws_vpc.openshift_vpc.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  // terraform removes the default rule
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
  gateway_id = aws_internet_gateway.cluster_igw.id
}
