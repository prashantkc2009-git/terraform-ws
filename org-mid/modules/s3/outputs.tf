# ==============================================================================
# Module: s3
# File: outputs.tf
# Description: Exports S3 bucket names and ARNs.
# ==============================================================================

output "app_logs_bucket_id" {
  value       = aws_s3_bucket.main["app_logs"].id
  description = "The ID/Name of the app logs S3 bucket."
}

output "app_logs_bucket_arn" {
  value       = aws_s3_bucket.main["app_logs"].arn
  description = "The ARN of the app logs S3 bucket."
}

output "data_lake_bucket_id" {
  value       = aws_s3_bucket.main["data_lake"].id
  description = "The ID/Name of the data lake S3 bucket."
}

output "data_lake_bucket_arn" {
  value       = aws_s3_bucket.main["data_lake"].arn
  description = "The ARN of the data lake S3 bucket."
}

output "backups_bucket_id" {
  value       = aws_s3_bucket.main["backups"].id
  description = "The ID/Name of the backups S3 bucket."
}

output "backups_bucket_arn" {
  value       = aws_s3_bucket.main["backups"].arn
  description = "The ARN of the backups S3 bucket."
}

output "static_assets_bucket_id" {
  value       = aws_s3_bucket.main["static_assets"].id
  description = "The ID/Name of the static assets S3 bucket."
}

output "static_assets_bucket_arn" {
  value       = aws_s3_bucket.main["static_assets"].arn
  description = "The ARN of the static assets S3 bucket."
}
