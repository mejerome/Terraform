

variable "cidr_block" {
  type        = string
  description = "VPC cidr-block"
  default     = "10.0.0.0/16"
}

variable "subnet_cdir" {
  type        = string
  description = "Subnet cidr-block"
  default     = "10.0.1.0/24"
}

variable "network_interface_privateip" {
  type        = string
  description = "Private IP for NIC"
  default     = "10.0.1.50"
}

variable "instance_ami" {
  type        = string
  description = "The AMI for instance"
  default     = "ami-09e67e426f25ce0d7"
}

variable "instance_type" {
  type        = string
  description = "The type of instance"
  default     = "t2.small"
}

variable "instance_key_name" {
  type        = string
  description = "The keyname for instance"
  default     = "afari"
}

variable "allowed_cidr" {
  type        = string
  description = "cidr block for allowed ports"
  default     = "0.0.0.0/0"
}

variable "access_port" {
  type        = string
  description = "Port to allow in security group for access"
  default     = 3389
}

#Tags
variable "vpc_tag" {
  type        = string
  description = "VPC tag"
  default     = "gbala"
}

variable "internet_gateway_tag" {
  type        = string
  description = "Internet gateway tag"
  default     = "gbala_gw"
}

variable "route_table_tag" {
  type        = string
  description = "Route table tag"
  default     = "gbala_rt"
}

variable "subnet_tag" {
  type        = string
  description = "Subnet tag"
  default     = "gbala_subnet-1"
}
