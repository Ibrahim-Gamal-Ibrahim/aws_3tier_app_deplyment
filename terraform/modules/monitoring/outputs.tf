output "sns_topic_arn" {
  description = "SNS topic used for infrastructure alerts"
  value       = aws_sns_topic.alerts.arn
}

output "frontend_high_cpu_alarm_name" {
  description = "Name of the frontend ASG high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.frontend_high_cpu.alarm_name
}

output "backend_high_cpu_alarm_name" {
  description = "Name of the backend ASG high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.backend_high_cpu.alarm_name
}

output "frontend_unhealthy_targets_alarm_name" {
  description = "Name of the frontend unhealthy targets alarm"
  value       = aws_cloudwatch_metric_alarm.frontend_unhealthy_targets.alarm_name
}

output "backend_unhealthy_targets_alarm_name" {
  description = "Name of the backend unhealthy targets alarm"
  value       = aws_cloudwatch_metric_alarm.backend_unhealthy_targets.alarm_name
}

output "rds_cpu_alarm_name" {
  description = "Name of the RDS high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.rds_high_cpu.alarm_name
}

output "rds_storage_alarm_name" {
  description = "Name of the RDS low storage alarm"
  value       = aws_cloudwatch_metric_alarm.rds_low_storage.alarm_name
}