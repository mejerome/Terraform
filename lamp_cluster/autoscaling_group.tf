
resource "aws_launch_configuration" "web" {
  name_prefix   = "web-"
  image_id      = "ami-096cb92bb3580c759" # eu-west-2
  instance_type = "t3.micro"
  key_name      = "jt-london"

  # user_data       = file("install_apache.sh")
  security_groups = [aws_security_group.allow_ports.id]

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "web" {
  name                 = "terraform-asg-lamp"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 1
  desired_capacity     = 2
  max_size             = 4

  health_check_type = "ELB"
  load_balancers    = [aws_elb.web.id]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier = [aws_subnet.public_sub.id]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_dns},' --private-key '${var.private_key}' apache-install.yml"
  }

  tags = [{
    Name = "web-group"
  }]

}

resource "aws_elb" "web" {
  name = "lamp-terraform-elb"

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = "80"
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  subnets                     = [aws_subnet.public_sub.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  security_groups             = [aws_security_group.allow_ports.id]

  tags = {
    Name = "lamp-terraform-elb"
  }
}
