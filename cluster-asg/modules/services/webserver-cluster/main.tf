# provider "aws" {
#   profile = "default"
#   region  = "us-east-2"
# }

#Remote backend
terraform {
  backend "s3" {
    bucket = "mejerome-terraform-up-and-running-state"
    key    = "webserver-cluster/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "mejerome-terraform-up-and-running-locks"
    encrypt        = true
  }
}


#Data
data "terraform_remote_state" "cat_db" {
  backend = "s3"
  config = {
    bucket = "mejerome-terraform-up-and-running-state"
    key    = "mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    db_address = data.terraform_remote_state.cat_db.outputs.address
    db_port    = data.terraform_remote_state.cat_db.outputs.port
  }
}

# Cluster VPC
resource "aws_vpc" "cluster_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Cluster VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.cluster_vpc.id
  cidr_block = "10.0.0.0/24"

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

#Launch configuration for webservers
resource "aws_launch_configuration" "web" {
  name_prefix   = "web-"
  image_id      = "ami-01aab85a5e4a5a0fe"
  instance_type = "t2.micro"
  key_name      = "jerome-key"

  security_groups             = [aws_security_group.allow_http.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

# Load balancer
resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through ELB"
  vpc_id      = aws_vpc.cluster_vpc.id

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

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}

resource "aws_elb" "web_elb" {
  name            = "web-elb"
  security_groups = [aws_security_group.elb_http.id]

  subnets                   = [aws_subnet.public_subnet.id]
  cross_zone_load_balancing = true

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:80/"
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }
  tags = {
    Name = "cluster-elb"
  }
}

#Autoscaling group
resource "aws_autoscaling_group" "web" {
  name                = "${aws_launch_configuration.web.name}-asg"
  min_size            = 1
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.public_subnet.id]

  health_check_type = "ELB"
  load_balancers    = [aws_elb.web_elb.id]

  launch_configuration = aws_launch_configuration.web.name
  lifecycle {
    create_before_destroy = true
  }
}
