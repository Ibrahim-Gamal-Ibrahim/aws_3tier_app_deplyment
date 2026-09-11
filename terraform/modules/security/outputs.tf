output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "frontend_sg_id" {
  value = aws_security_group.frontend.id
}

output "internal_alb_sg_id" {
  value = aws_security_group.internal_alb.id
}

output "backend_sg_id" {
  value = aws_security_group.backend.id
}

output "database_sg_id" {
  value = aws_security_group.database.id
}