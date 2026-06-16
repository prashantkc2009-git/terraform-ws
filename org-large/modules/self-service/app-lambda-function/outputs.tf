output "function_name" {
  value       = aws_lambda_function.main.function_name
  description = "Lambda function name"
}

output "function_arn" {
  value       = aws_lambda_function.main.arn
  description = "Lambda function ARN"
}

output "invoke_arn" {
  value       = aws_lambda_function.main.invoke_arn
  description = "Lambda invoke ARN"
}

output "role_arn" {
  value       = aws_iam_role.main.arn
  description = "Lambda IAM role ARN"
}

output "qualified_arn" {
  value       = aws_lambda_function.main.qualified_arn
  description = "Lambda qualified ARN (with version)"
}

output "version" {
  value       = aws_lambda_function.main.version
  description = "Lambda function version"
}
