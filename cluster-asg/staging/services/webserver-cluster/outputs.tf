
output "alb_dns_name" {
  value       = aws_lb.cat.dns_name
  description = "Domain name of LB"
}
