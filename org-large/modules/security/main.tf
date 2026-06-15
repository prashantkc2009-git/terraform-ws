# ==============================================================================
# Module: security
# File: main.tf
# Description: Configures KMS multi-region keys, WAF rules, and Developer Boundaries.
# ==============================================================================

# 1. Multi-Region KMS Key (primary in us-east-1, replica in eu-west-1)
# Note: In multi-region deployments, the replica is configured in the secondary region referencing the primary key.
# Here we define the primary Multi-Region Key.
resource "aws_kms_key" "mrk_primary" {
  description             = "Multi-Region Primary KMS key for storage and databases"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-mrk"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "mrk_primary_alias" {
  name          = "alias/mrk-${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.mrk_primary.key_id
}

# 2. Developer Policy Boundary (DeveloperPolicyBoundary)
# Restricts modifying VPC configurations, altering routing, or database access outside subnets.
resource "aws_iam_policy" "developer_boundary" {
  name        = "DeveloperPolicyBoundary"
  description = "Permission Boundary for application development teams."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowMostActions"
        Effect = "Allow"
        NotAction = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateRoute*",
          "ec2:DeleteRoute*",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDatabaseDirectAccess"
        Effect = "Deny"
        Action = [
          "rds-data:*"
        ]
        Resource = "arn:aws:rds:*:*:db:*"
      }
    ]
  })
}

# 3. WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-${var.environment}-waf"
  description = "Global API WAF Gateway"
  scope       = "REGIONAL" # Or CLOUDFRONT depending on deployment location

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFSQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFKnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFMainACLMetric"
    sampled_requests_enabled   = true
  }

  tags = {
    Environment = var.environment
  }
}
