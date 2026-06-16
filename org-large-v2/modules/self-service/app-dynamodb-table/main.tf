resource "aws_dynamodb_table" "main" {
  name             = "${var.app_name}-${var.environment}-${var.table_name}"
  billing_mode     = var.billing_mode
  hash_key         = var.hash_key
  range_key        = var.range_key
  stream_enabled   = var.enable_stream
  stream_view_type = var.enable_stream ? "NEW_AND_OLD_IMAGES" : null

  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
    }
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-${var.table_name}"
    Environment = var.environment
    AppName     = var.app_name
  }
}
