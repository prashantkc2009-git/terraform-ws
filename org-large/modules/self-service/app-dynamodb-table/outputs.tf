output "table_name" {
  value       = aws_dynamodb_table.main.name
  description = "DynamoDB table name"
}

output "table_arn" {
  value       = aws_dynamodb_table.main.arn
  description = "DynamoDB table ARN"
}

output "stream_arn" {
  value       = aws_dynamodb_table.main.stream_arn
  description = "DynamoDB stream ARN"
}
