# ==============================================================================
# Module: s3
# File: outputs.tf
# Description: Defines the outputs of the S3 module.
# ==============================================================================

output "bucket_id" {
  value       = aws_s3_bucket.assets.id
  description = "The name/ID of the assets bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.assets.arn
  description = "The ARN of the assets bucket."
}
