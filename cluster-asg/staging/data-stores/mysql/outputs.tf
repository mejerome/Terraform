output "address" {
  value       = aws_db_instance.cat_db.address
  description = "Database endpoint"
}

output "port" {
  value       = aws_db_instance.cat_db.port
  description = "Database port"
}
