resource "aws_security_group" "lambda" {
  name        = "frontend-lifecycle-lambda-sg"
  description = "Security group for frontend lifecycle Lambda"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "frontend-lifecycle-lambda-sg"
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_jenkins" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = var.jenkins_security_group_id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Allow frontend Lambda to call Jenkins"
}

resource "aws_vpc_security_group_ingress_rule" "lambda_to_jenkins" {
  security_group_id            = var.jenkins_security_group_id
  referenced_security_group_id = aws_security_group.lambda.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Allow frontend lifecycle Lambda to trigger Jenkins"
}

resource "aws_iam_role" "lambda" {
  name = "frontend-lifecycle-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "lambda.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "lambda" {
  type = "zip"

  source_file = "${path.module}/lambda/trigger_jenkins.py"
  output_path = "${path.module}/lambda/trigger_jenkins.zip"
}

resource "aws_lambda_function" "frontend_lifecycle" {
  function_name = "frontend-lifecycle-trigger-jenkins"

  role    = aws_iam_role.lambda.arn
  handler = "trigger_jenkins.lambda_handler"
  runtime = "python3.13"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout = 30

  vpc_config {
    subnet_ids = [
      var.private_subnet_a_id,
      var.private_subnet_b_id
    ]

    security_group_ids = [
      aws_security_group.lambda.id
    ]
  }

  environment {
    variables = {
      JENKINS_URL       = "http://${var.jenkins_private_ip}:8080"
      JENKINS_JOB       = var.jenkins_job_name
      JENKINS_USER      = var.jenkins_user
      JENKINS_API_TOKEN = var.jenkins_api_token
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc
  ]
}

resource "aws_cloudwatch_event_rule" "frontend_launch" {
  name        = "frontend-asg-lifecycle-launch"
  description = "Capture frontend ASG launch lifecycle events"

  event_pattern = jsonencode({
    source = [
      "aws.autoscaling"
    ]

    detail-type = [
      "EC2 Instance-launch Lifecycle Action"
    ]

    detail = {
      AutoScalingGroupName = [
        var.frontend_asg_name
      ]

      LifecycleHookName = [
        var.frontend_lifecycle_hook_name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.frontend_launch.name
  target_id = "frontend-lifecycle-lambda"
  arn       = aws_lambda_function.frontend_lifecycle.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.frontend_lifecycle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.frontend_launch.arn
}
