output "bucket_id" {
  value       = aws_s3_bucket.main.id
  description = "S3 Bucket ID"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "S3 Bucket ARN"
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.main.bucket_domain_name
  description = "S3 Bucket domain name"
}
