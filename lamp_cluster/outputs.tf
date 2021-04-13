output "elb_dns_name" {
  value = aws_instance.test.public_dns # aws_elb.web.dns_name
}
