variable "alert_email" {
  description = "Email address that receives infrastructure alerts"
  type        = string
}

variable "frontend_asg_name" {
  description = "Frontend Auto Scaling Group name"
  type        = string
}

variable "backend_asg_name" {
  description = "Backend Auto Scaling Group name"
  type        = string
}

variable "frontend_alb_arn_suffix" {
  type = string
}

variable "frontend_target_group_arn_suffix" {
  type = string
}

variable "backend_alb_arn_suffix" {
  type = string
}

variable "backend_target_group_arn_suffix" {
  type = string
}

variable "high_cpu_threshold" {
  description = "CPU threshold that triggers an operational alert"
  type        = number
  default     = 70
}

variable "db_instance_identifier" {
  description = "RDS DB instance identifier used for CloudWatch metrics"
  type        = string
}