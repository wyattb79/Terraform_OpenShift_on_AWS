variable "stack_name" {
  type = string
  default = "OpenShift VPC"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type = string
  default = "10.0.1.0/28"
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "login_ip" {
  type = string
  default = "1.2.3.4/32"
}

variable "control_plane_type" {
  type = string
  default = "t2.micro"
}

variable "control_plane_nodes" {
  type = number
  default = 2
}

variable "key_name" {
  type = string
  default = "key"
}
