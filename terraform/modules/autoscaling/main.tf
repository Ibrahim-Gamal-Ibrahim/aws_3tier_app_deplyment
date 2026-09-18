resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [
    var.security_group_id
  ]

  monitoring {
    enabled = true
  }

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = var.name
      Role        = var.role
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name = "${var.name}-asg"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = [
    var.private_subnet_a_id,
    var.private_subnet_b_id
  ]

  target_group_arns = [
    var.target_group_arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 600   #After a new EC2 instance is launched into the Auto Scaling Group, ASG waits 600 seconds = 10 minutes before it starts using health check failures to decide that the instance is unhealthy and replace it.

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_value
  }
}