output "s3_bucket_id" {
  value       = module.app_s3_bucket_example.bucket_id
  description = "Example app S3 bucket ID"
}

output "s3_bucket_arn" {
  value       = module.app_s3_bucket_example.bucket_arn
  description = "Example app S3 bucket ARN"
}
