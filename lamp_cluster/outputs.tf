output "elb_dns_name" {
  value = aws_elb.web.dns_name #aws_instance.test.public_dns 
}
