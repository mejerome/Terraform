provider "aws" {
  region  = "us-east-2"
  shared_credentials_file  = "~/.aws/credentials"
  profile = "admin"
}

resource "aws_instance" "web" {
  ami             = "ami-0a0ad6b70e61be944"
  instance_type   = "t2.micro"
  key_name        = "jerome-key"
  security_groups = [aws_security_group.web-sg.name]

  tags = {
    "Name" = "WebServerTF"
  }
}

resource "aws_security_group" "web-sg" {
  name        = "Web security group"
  description = "Allow access to webserver"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_public_dns" {
  value = aws_instance.web.public_dns
}