output "alb_dns_name" {
  description = "DNS name of the public frontend ALB"
  value       = aws_lb.main.dns_name
}

output "application_url" {
  description = "HTTPS URL of the application"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

output "target_group_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix used for ALB CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix used for frontend target group CloudWatch metrics"
  value       = aws_lb_target_group.frontend.arn_suffix
}