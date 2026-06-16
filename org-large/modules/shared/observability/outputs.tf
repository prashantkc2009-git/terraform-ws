output "thanos_bucket_id" {
  value       = aws_s3_bucket.thanos_store.id
  description = "Thanos S3 Bucket ID"
}

output "thanos_bucket_arn" {
  value       = aws_s3_bucket.thanos_store.arn
  description = "Thanos S3 Bucket ARN"
}

output "log_archive_bucket_id" {
  value       = aws_s3_bucket.log_archive.id
  description = "Log Archive S3 Bucket ID"
}

output "log_archive_bucket_arn" {
  value       = aws_s3_bucket.log_archive.arn
  description = "Log Archive S3 Bucket ARN"
}

output "flow_log_group_name" {
  value       = aws_cloudwatch_log_group.flow_logs.name
  description = "VPC Flow Logs CloudWatch Log Group"
}
