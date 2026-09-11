output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "db_instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.postgres.identifier
}