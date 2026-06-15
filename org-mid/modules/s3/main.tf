# ==============================================================================
# Module: s3
# File: main.tf
# Description: Implements S3 bucket layout, versioning, SSE-KMS, and lifecycle rules.
# ==============================================================================

# Helper list of buckets
locals {
  buckets = {
    app_logs      = "app-logs"
    data_lake     = "data-lake"
    backups       = "backups"
    static_assets = "static-assets"
  }
}

resource "aws_s3_bucket" "main" {
  for_each = local.buckets

  bucket        = "${var.project_name}-${var.environment}-${each.value}"
  force_destroy = var.environment != "prod"

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.value}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.main["app_logs"].id

  rule {
    id     = "logs-lifecycle"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.main["backups"].id

  rule {
    id     = "backups-lifecycle"
    status = "Enabled"

    filter {}

    expiration {
      days = 35
    }

    noncurrent_version_expiration {
      noncurrent_days = 35
    }
  }
}
