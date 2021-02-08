provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

# terraform {
#   backend "s3" {
#     bucket         = "mejerome-terraform-up-and-running-state"
#     key            = "workspaces-eg/terraform.tfstate"
#     region         = "us-east-2"
#     dynamodb_table = "mejerome-terraform-up-and-running-locks"
#     encrypt        = true
#   }
# }

# Cluster VPC
resource "aws_vpc" "cluster_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Cluster VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.cluster_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public subnet"
  }
}
resource "aws_internet_gateway" "vpc_gw" {
  vpc_id = aws_vpc.cluster_vpc.id

  tags = {
    Name = "VPC internet gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cluster_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_gw.id
  }

  tags = {
    Name = "Public route table"
  }
}

resource "aws_route_table_association" "public_rt" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security groups
resource "aws_security_group" "allow_http" {
  name        = "Allow HTTP"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.cluster_vpc.id
  ingress {
    description = "HTTP to VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH to VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_instance" "example" {
  ami             = "ami-01aab85a5e4a5a0fe"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_http.id]
  subnet_id       = aws_subnet.public_subnet.id
  user_data       = <<EOF
    #!/bin/bash
    sudo yum update
    sudo yum -y install httpd
    systemctl start httpd.service
    systemctl enable httpd.service
    echo "<h1>Fa no s3 wagyimi...from $(hostname -f)</h1>" > /var/www/html/index.html
    EOF
  tags = {
    Name = "example"
  }
}


output "instance_public_ip" {
  value = aws_instance.example.public_ip
}

output "instance_public_dns" {
  value = aws_instance.example.public_dns
}
