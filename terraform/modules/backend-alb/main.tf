resource "aws_lb" "backend" {
  name               = "backend-internal-alb"
  internal           = true
  load_balancer_type = "application"

  security_groups = [
    var.internal_alb_sg_id
  ]

  subnets = [
    var.private_subnet_a_id,
    var.private_subnet_b_id
  ]

  tags = {
    Name = "backend-internal-alb"
  }
}

resource "aws_lb_target_group" "backend" {
  name     = "backend-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
  enabled             = true
  path                = "/health"
  protocol            = "HTTP"
  port                = "traffic-port"

  interval            = 30
  timeout             = 10

  healthy_threshold   = 2
  unhealthy_threshold = 6

  matcher             = "200"
}

  tags = {
    Name = "backend-target-group"
  }
}

resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.backend.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}