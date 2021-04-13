provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

terraform {
  backend "s3" {
    key    = "lamp-cluster/terraform.tfstate"
    bucket = "mejerome-terraform-up-and-running-state"
    region = "us-east-2"
  }
}

variable "private_key" {
  type    = string
  default = "../../../jt-london.pem"
}

resource "aws_instance" "test" {
  ami             = "ami-096cb92bb3580c759" # eu-west-2
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_sub.id
  security_groups = [aws_security_group.allow_ports.id]
  key_name        = "jt-london"

  tags = {
    Name = "network-tester"
  }

  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_dns},' --private-key '${var.private_key}' apache-install.yml"
  }
}
