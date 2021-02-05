provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "mejerome-terraform-up-and-running-state"
    key    = "webserver-cluster/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "mejerome-terraform-up-and-running-locks"
    encrypt        = true
  }
}

# get default VPC id
data "aws_vpc" "default" {
  default = true
}

# get subnet ids from API
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Security group resource for webservers
resource "aws_security_group" "cat_sg" {
  name = "cat security group"
  ingress {
    from_port   = var.allow_port
    to_port     = var.allow_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# launch configuration template
resource "aws_launch_configuration" "cat" {
  image_id        = "ami-01aab85a5e4a5a0fe"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.cat_sg.id]
  user_data       = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y nginx
        echo "<h1>Fa no s3 wagyimi....</h1>" > /usr/share/nginx/html/index.html
        chkconfig nginx on
        service nginx start
        EOF
  lifecycle {
    create_before_destroy = true
  }
}

# Security group for load balancer
resource "aws_security_group" "alb" {
  name = "cat-asg-example"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "name" {
  name            = "web-elb"
  security_groups = [aws_security_group.alb.id]
}

# auto scaling group
resource "aws_autoscaling_group" "cat" {
  launch_configuration = aws_launch_configuration.cat.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"
  min_size             = 2
  max_size             = 5

  tag {
    key                 = "Name"
    value               = "cat-asg-example"
    propagate_at_launch = true
  }
}
