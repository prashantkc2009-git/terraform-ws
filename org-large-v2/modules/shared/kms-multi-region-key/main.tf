resource "aws_kms_key" "mrk_primary" {
  description             = "Multi-Region Primary KMS key for storage and databases"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = true

  policy = var.key_policy != null ? var.key_policy : data.aws_iam_policy_document.default_kms_policy.json

  tags = {
    Name        = "${var.project_name}-${var.environment}-mrk"
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "default_kms_policy" {
  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_alias" "mrk_primary_alias" {
  name          = "alias/mrk-${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.mrk_primary.key_id
}
