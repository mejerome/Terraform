provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

terraform {
  backend "s3" {
    bucket         = "mejerome-terraform-up-and-running-state"
    key            = "webserver-cluster/terraform.tfstate"
    region         = "us-east-2"
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
resource "aws_security_group" "cat-sg" {
  name = "cat security group"
  ingress {
    from_port   = var.allow_port
    to_port     = var.allow_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# launch configuration template
resource "aws_launch_configuration" "cat" {
  image_id        = "ami-0a91cd140a1fc148a"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.cat-sg.id]
  user_data       = <<-EOF
        #!/bin/bash
        echo "Fa now s3 wagyimi na suro mbaa" > /var/www/test/index.html
        sudo apt update
        sudo apt install apache2
        sudo systemctl restart apache2
        EOF
  lifecycle {
    create_before_destroy = true
  }
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

# Elastic load balancer
resource "aws_lb" "cat" {
  name               = "cat-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# Load balancer listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.cat.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# Target group for ASG
resource "aws_lb_target_group" "asg" {
  name     = "cat-asg-example"
  port     = var.allow_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Load balancer listener rule
resource "aws_alb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern { values = ["*"] }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
