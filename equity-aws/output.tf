output "availability_zone" {
  description = "List of availability zones of instances"
  value       = aws_instance.gbala_instance.availability_zone
}

output "public_dns" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = aws_instance.gbala_instance.public_dns
}

output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = aws_instance.gbala_instance.public_ip
}