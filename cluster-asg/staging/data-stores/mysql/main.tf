provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "mejerome-terraform-up-and-running-state"
    key    = "mysql/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "mejerome-terraform-up-and-running-locks"
    encrypt        = true
  }
}

resource "aws_db_instance" "cat_db" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  name                = "cat_db_example"
  username            = "admin"
  password            = var.db_password
  skip_final_snapshot = true
}
