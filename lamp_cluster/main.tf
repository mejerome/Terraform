provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

terraform {
  backend "s3" {
    key    = "lamp-cluster/terraform.tfstate"
    bucket = "mejerome-terraform-up-and-running-state"
    region = "us-east-2"
  }
}

resource "aws_instance" "test" {
  ami             = "ami-05d72852800cbf29e" # us-east-2
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_sub.id
  security_groups = [aws_security_group.allow_ports.id]
  key_name        = "jerome-key"

  tags = {
    Name = "network-tester"
  }
}
