resource "aws_s3_bucket" "thanos_store" {
  bucket        = "${var.project_name}-${var.environment}-thanos-telemetry"
  force_destroy = var.environment == "prod" ? false : true

  tags = {
    Name        = "${var.project_name}-${var.environment}-thanos-telemetry"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "thanos_enc" {
  bucket = aws_s3_bucket.thanos_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "thanos_block" {
  bucket                  = aws_s3_bucket.thanos_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "log_archive" {
  bucket        = "${var.project_name}-${var.environment}-log-archive"
  force_destroy = var.environment == "prod" ? false : true
  object_lock_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-log-archive"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_object_lock_configuration" "log_archive_lock" {
  bucket = aws_s3_bucket.log_archive.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 2555
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_archive_block" {
  bucket                  = aws_s3_bucket.log_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}-${var.environment}"
  retention_in_days = 90
}

resource "aws_iam_role" "flow_logs_role" {
  name = "${var.project_name}-${var.environment}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "${var.project_name}-${var.environment}-flow-logs-policy"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc_logs" {
  iam_role_arn    = aws_iam_role.flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id
}
