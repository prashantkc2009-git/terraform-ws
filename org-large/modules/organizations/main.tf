# ==============================================================================
# Module: organizations
# File: main.tf
# Description: Configures AWS Organizations, OUs, accounts, and SCPs.
# ==============================================================================

resource "aws_organizations_organization" "org" {
  count = var.environment == "prod" ? 1 : 0

  feature_set = "ALL"
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

# ------------------------------------------------------------------------------
# Organizational Units (OUs)
# ------------------------------------------------------------------------------
resource "aws_organizations_organizational_unit" "security" {
  count     = var.environment == "prod" ? 1 : 0
  name      = "Security"
  parent_id = aws_organizations_organization.org[0].roots[0].id
}

resource "aws_organizations_organizational_unit" "core_infra" {
  count     = var.environment == "prod" ? 1 : 0
  name      = "CoreInfrastructure"
  parent_id = aws_organizations_organization.org[0].roots[0].id
}

resource "aws_organizations_organizational_unit" "business_lobs" {
  count     = var.environment == "prod" ? 1 : 0
  name      = "BusinessLOBs"
  parent_id = aws_organizations_organization.org[0].roots[0].id
}

resource "aws_organizations_organizational_unit" "sandboxes" {
  count     = var.environment == "prod" ? 1 : 0
  name      = "Sandboxes"
  parent_id = aws_organizations_organization.org[0].roots[0].id
}

# ------------------------------------------------------------------------------
# Service Control Policies (SCPs)
# ------------------------------------------------------------------------------
resource "aws_organizations_policy" "enterprise_scp" {
  count       = var.enable_scp && var.environment == "prod" ? 1 : 0
  name        = "EnterpriseSecurityGuardrails"
  description = "SCPs to restrict disabling security services, require encryption, enforce EU residency, and restrict regions."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDisablingSecurityServices"
        Effect = "Deny"
        Action = [
          "guardduty:Delete*",
          "guardduty:Archive*",
          "securityhub:Delete*",
          "securityhub:Disable*",
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyUnencryptedResources"
        Effect = "Deny"
        Action = [
          "ec2:CreateVolume",
          "rds:CreateDBInstance",
          "s3:PutBucketEncryption"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "EnforceGDPRDataResidency"
        Effect = "Deny"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::*-eu-data/*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "eu-west-1",
              "eu-central-1"
            ]
          }
        }
      },
      {
        Sid      = "RestrictRegions"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "us-east-1",
              "us-west-2",
              "eu-west-1",
              "eu-central-1"
            ]
          }
        }
      }
    ]
  })
}

# Attach SCP to Root
resource "aws_organizations_policy_attachment" "root_scp" {
  count     = var.enable_scp && var.environment == "prod" ? 1 : 0
  policy_id = aws_organizations_policy.enterprise_scp[0].id
  target_id = aws_organizations_organization.org[0].roots[0].id
}
