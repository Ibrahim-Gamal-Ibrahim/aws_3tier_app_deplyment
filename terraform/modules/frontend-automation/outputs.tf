output "lambda_function_name" {
  value = aws_lambda_function.frontend_lifecycle.function_name
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}

output "eventbridge_rule_name" {
  value = aws_cloudwatch_event_rule.frontend_launch.name
}
