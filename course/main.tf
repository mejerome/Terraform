provider "aws" {
  region                  = "us-east-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}

locals {
  tags = {
    Name = "efie"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = local.tags
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = local.tags
}


resource "aws_security_group" "main_sg" {
  name        = "allow_SSH"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0a0ad6b70e61be944"
  instance_type = "t3.micro"
  key_name      = "jerome-hm"
  subnet_id     = aws_subnet.main_subnet.id

  security_groups = [aws_security_group.main_sg.id]

  tags = local.tags
}

output "instance_public_dns" {
  value = aws_instance.web.public_dns
}