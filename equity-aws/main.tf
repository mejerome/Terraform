provider "aws" {
  profile = "admin"
  region  = "us-east-1"
}

# 1. Create VPC
resource "aws_vpc" "gbala_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_tag
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.gbala_vpc.id

  tags = {
    Name = var.internet_gateway_tag
  }
}

# 3. Create custom route table
resource "aws_route_table" "gbala_rt" {
  vpc_id = aws_vpc.gbala_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.route_table_tag
  }
}

# 4. Create subnet
resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.gbala_vpc.id
  cidr_block              = var.subnet_cdir
  depends_on              = [aws_internet_gateway.gw]
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet_tag
  }
}

# 5. Associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.gbala_rt.id
}

# 6. Create security group
resource "aws_security_group" "allow_gbala" {
  name        = "allow_traffic"
  description = "Allow traffic"
  vpc_id      = aws_vpc.gbala_vpc.id

  ingress {
    description = "RDP to VPC"
    from_port   = var.access_port
    to_port     = var.access_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "HTTP to VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_traffic"
  }
}

# 7. Create network interface with an IP in subnet
resource "aws_network_interface" "gbala_nic" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = [var.network_interface_privateip]
  security_groups = [aws_security_group.allow_gbala.id]

  tags = {
    Name = "gbala_nic"
  }
}

# 8. Assign elastic IP to network interface
resource "aws_eip" "gbala" {
  vpc = true

  network_interface         = aws_network_interface.gbala_nic.id
  associate_with_private_ip = var.network_interface_privateip
  depends_on                = [aws_internet_gateway.gw, aws_network_interface.gbala_nic]
}

# 9. Create windows instance install xampp
resource "aws_instance" "gbala_instance" {
  ami               = var.instance_ami # us-west-2
  instance_type     = var.instance_type
  key_name          = var.instance_key_name
  get_password_data = true

  network_interface {
    network_interface_id = aws_network_interface.gbala_nic.id
    device_index         = 0
  }

  tags = {
    Name = "gbala_instance"
  }

}
# 10. Join a domain

