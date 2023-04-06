variable "stack_name" {
  type    = string
  default = "OpenShift VPC"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "login_ip" {
  type    = string
  default = "1.2.3.4/32"
}

variable "control_plane_type" {
  type    = string
  default = "t2.micro"
}

variable "worker_node_type" {
  type    = string
  default = "t2.micro"
}
variable "control_plane_nodes" {
  type    = number
  default = 1
}

variable "worker_nodes" {
  type    = number
  default = 1
}

variable "key_name" {
  type    = string
  default = "key"
}
