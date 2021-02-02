provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

terraform {
  backend "s3" {
    bucket         = "mejerome-terraform-up-and-running-state"
    key            = "workspaces-eg/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "mejerome-terraform-up-and-running-locks"
    encrypt        = true
  }
}

resource "aws_instance" "example" {
  ami           = "ami-052b4c680fa852872"
  instance_type = "t2.micro"
}
