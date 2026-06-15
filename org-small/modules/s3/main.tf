# ==============================================================================
# Module: s3
# File: main.tf
# Description: Provisions S3 buckets with server-side KMS encryption, versioning,
#              and public access block.
# ==============================================================================

resource "aws_s3_bucket" "assets" {
  bucket        = "${var.project_name}-${var.environment}-assets-bucket-unique"
  force_destroy = var.environment == "prod" ? false : true

  tags = {
    Name        = "${var.project_name}-${var.environment}-assets"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}
