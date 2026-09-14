output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "dns_name" {
  value = aws_lb.backend.dns_name
}

output "alb_arn_suffix" {
  value = aws_lb.backend.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.backend.arn_suffix
}

