output "state_bucket_id" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Terraform State S3 Bucket ID"
}

output "state_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "Terraform State S3 Bucket ARN"
}

output "dynamodb_lock_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table name for state locking"
}

output "kms_key_arn" {
  value       = aws_kms_key.terraform_state.arn
  description = "KMS key ARN for state encryption"
}
