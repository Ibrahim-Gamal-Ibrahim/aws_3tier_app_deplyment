output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_a_id" {
  value = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.public_b.id
}

output "private_subnet_a_id" {
  value = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private_b.id
}
output "db_subnet_a_id" {
  description = "Database subnet A ID"
  value       = aws_subnet.db_a.id
}

output "db_subnet_b_id" {
  description = "Database subnet B ID"
  value       = aws_subnet.db_b.id
}