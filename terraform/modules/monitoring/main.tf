# this means if cloudwatch does not get a data in an evaluation_period consider that it is okay
# wee need to initiate an alram if we recieve a data in a suucssive way (may be a spark only) 
#asks CloudWatch to aggregate the EC2 metric for instances belonging to that ASG
#creation of the SNS Topic to wich cloudwatch alarmes will publish and my mail will subuscribe 
resource "aws_sns_topic" "alerts" {
  name = "terraform-infrastructure-alerts"

  tags = {
    Name        = "terraform-infrastructure-alerts"
    Environment = "dev"
  }
}
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# High instance`s CPU alret configuration
resource "aws_cloudwatch_metric_alarm" "frontend_high_cpu" {
  alarm_name        = "frontend-asg-high-cpu"
  alarm_description = "Frontend ASG average CPU is above 70 percent"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 5

  comparison_operator = "GreaterThanThreshold"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = var.frontend_asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name        = "backend-asg-high-cpu"
  alarm_description = "Backend ASG average CPU is above 70 percent"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 5

  comparison_operator = "GreaterThanThreshold"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = var.backend_asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

# ALB unhealthy targets alarm`s configuration 
resource "aws_cloudwatch_metric_alarm" "frontend_unhealthy_targets" {
  alarm_name        = "frontend-unhealthy-targets"
  alarm_description = "One or more frontend targets are unhealthy"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  statistic          = "Maximum"
  period             = 60
  evaluation_periods = 2

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  dimensions = {
    LoadBalancer = var.frontend_alb_arn_suffix
    TargetGroup  = var.frontend_target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "backend_unhealthy_targets" {
  alarm_name        = "backend-unhealthy-targets"
  alarm_description = "One or more backend targets are unhealthy"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  statistic          = "Maximum"
  period             = 60
  evaluation_periods = 2

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  dimensions = {
    LoadBalancer = var.backend_alb_arn_suffix
    TargetGroup  = var.backend_target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "backend_target_5xx" {
  alarm_name        = "backend-target-5xx"
  alarm_description = "Backend targets are returning HTTP 5xx responses"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  statistic          = "Sum"
  period             = 60
  evaluation_periods = 2

  comparison_operator = "GreaterThanThreshold"
  threshold           = 5

  dimensions = {
    LoadBalancer = var.backend_alb_arn_suffix
    TargetGroup  = var.backend_target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "backend_response_time" {
  alarm_name        = "backend-high-response-time"
  alarm_description = "Backend target response time is high"

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 3

  comparison_operator = "GreaterThanThreshold"
  threshold           = 1

  dimensions = {
    LoadBalancer = var.backend_alb_arn_suffix
    TargetGroup  = var.backend_target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}
# alarm for the failed https connection on the frontend ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "frontend-alb-5xx-errors"
  alarm_description = "Public frontend ALB is generating HTTP 5xx responses"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  statistic          = "Sum"
  period             = 60
  evaluation_periods = 2

  comparison_operator = "GreaterThanThreshold"
  threshold           = 5

  dimensions = {
    LoadBalancer = var.frontend_alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}
# alarm for the failed https connection on the backend ALB
resource "aws_cloudwatch_metric_alarm" "backend_alb_5xx" {
  alarm_name        = "backend-alb-5xx-errors"
  alarm_description = "Internal backend ALB is generating HTTP 5xx responses"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  statistic          = "Sum"
  period             = 60
  evaluation_periods = 2

  comparison_operator = "GreaterThanThreshold"
  threshold           = 5

  dimensions = {
    LoadBalancer = var.backend_alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

# to notify me with the autoscaling events
resource "aws_autoscaling_notification" "asg_events" {
  group_names = [
    var.frontend_asg_name,
    var.backend_asg_name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]

  topic_arn = aws_sns_topic.alerts.arn
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name        = "rds-high-cpu"
  alarm_description = "RDS CPU utilization is above 80 percent"

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 5

  comparison_operator = "GreaterThanThreshold"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name        = "rds-low-free-storage"
  alarm_description = "RDS free storage space is below 5 GiB"

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 5

  comparison_operator = "LessThanThreshold"

  threshold = 5368709120 #bytes which equals 5GB

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_low_memory" {
  alarm_name        = "rds-low-freeable-memory"
  alarm_description = "RDS freeable memory is below 256 MiB"

  namespace   = "AWS/RDS"
  metric_name = "FreeableMemory"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 5

  comparison_operator = "LessThanThreshold"

  threshold = 268435456 # bytes which equals 256 MiB

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}
resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name        = "rds-high-database-connections"
  alarm_description = "RDS database connection count is unusually high"

  namespace   = "AWS/RDS"
  metric_name = "DatabaseConnections"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 5

  comparison_operator = "GreaterThanThreshold"
  threshold           = 50

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}
resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name        = "rds-high-read-latency"
  alarm_description = "RDS read latency is high"

  namespace   = "AWS/RDS"
  metric_name = "ReadLatency"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 5

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0.02 #2mS

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}
resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name        = "rds-high-write-latency"
  alarm_description = "RDS write latency is high"

  namespace   = "AWS/RDS"
  metric_name = "WriteLatency"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 5

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0.02

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}