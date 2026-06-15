# ==============================================================================
# Module: organizations
# File: main.tf
# Description: Configures OUs and SCPs for org-mid.
# ==============================================================================

resource "aws_organizations_organization" "org" {
  count = var.environment == "prod" ? 1 : 0 # Only attempt to initialize org structure in production root environment.

  feature_set = "ALL"
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

# Organizational Units
resource "aws_organizations_organizational_unit" "security" {
  count     = var.environment == "prod" ? 1 : 0
  name      = "ou-security"
  parent_id = aws_organizations_organization.org[0].roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  count     = var.environment == "prod" ? 1 : 0
  name      = "ou-infrastructure"
  parent_id = aws_organizations_organization.org[0].roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  count     = var.environment == "prod" ? 1 : 0
  name      = "ou-workloads"
  parent_id = aws_organizations_organization.org[0].roots[0].id
}

# SCP: Deny root user actions
resource "aws_organizations_policy" "deny_root" {
  count       = var.enable_scp && var.environment == "prod" ? 1 : 0
  name        = "deny-root-actions"
  description = "Deny root user actions across the Organization"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyRootActions"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "security_ou" {
  count     = var.enable_scp && var.environment == "prod" ? 1 : 0
  policy_id = aws_organizations_policy.deny_root[0].id
  target_id = aws_organizations_organizational_unit.security[0].id
}
