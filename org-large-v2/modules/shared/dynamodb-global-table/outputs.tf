output "table_name" {
  value       = aws_dynamodb_table.main.name
  description = "DynamoDB Table name"
}

output "table_arn" {
  value       = aws_dynamodb_table.main.arn
  description = "DynamoDB Table ARN"
}

output "table_id" {
  value       = aws_dynamodb_table.main.id
  description = "DynamoDB Table ID"
}

output "stream_arn" {
  value       = aws_dynamodb_table.main.stream_arn
  description = "DynamoDB Table Stream ARN"
}
