resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "jenkins-sg"
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh" {
  security_group_id = aws_security_group.jenkins.id

  cidr_ipv4 = var.admin_cidr

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  description = "Allow SSH from admin IP"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_web" {
  security_group_id = aws_security_group.jenkins.id

  cidr_ipv4 = var.admin_cidr

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Allow Jenkins UI from admin IP"
}

resource "aws_vpc_security_group_egress_rule" "jenkins_all" {
  security_group_id = aws_security_group.jenkins.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow all outbound traffic"
}


resource "aws_iam_role" "jenkins" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "jenkins" {
  name = "${var.name}-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",

          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:RecordLifecycleActionHeartbeat",

          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",

          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.jenkins.name
}

resource "aws_instance" "jenkins" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.jenkins.id
  ]

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.name}-server"
    Role        = "jenkins"
    Environment = "dev"
  }
}

