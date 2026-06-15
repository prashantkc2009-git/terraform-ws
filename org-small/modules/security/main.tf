# ==============================================================================
# Module: security
# File: main.tf
# Description: Provisions KMS keys for encryption at-rest, baseline security
#              groups (ALB, private tier, data tier), and completes ACM cert
#              DNS validation. Decoupled using SSM data lookups.
# ==============================================================================

# ------------------------------------------------------------------------------
# DATA SOURCES FOR COUPLING (SSM Parameter Store Lookups)
# ------------------------------------------------------------------------------
data "aws_ssm_parameter" "vpc_id" {
  name = "/company-small/${var.environment}/networking/vpc_id"
}

# ------------------------------------------------------------------------------
# KMS CUSTOMER MANAGED KEYS (CMK)
# ------------------------------------------------------------------------------
resource "aws_kms_key" "main" {
  description             = "Master key for ${var.project_name}-${var.environment} resource encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-kms-key"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}-key"
  target_key_id = aws_kms_key.main.key_id
}

# ------------------------------------------------------------------------------
# SECURITY GROUPS (Tier-Based Microsegmentation)
# ------------------------------------------------------------------------------

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allows ingress from internet to ALB"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Private Application Security Group
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Allows ingress from ALB SG only"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "gRPC from ALB"
    from_port       = 50051
    to_port         = 50051
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Data Layer Security Group
resource "aws_security_group" "data" {
  name        = "${var.project_name}-${var.environment}-data-sg"
  description = "Allows ingress to Databases from App SG only"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    description     = "PostgreSQL from App Tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "Redis from App Tier"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "NFS for EFS from App Tier"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-data-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# SSM VPC Endpoint Security Group
resource "aws_security_group" "ssm_endpoints" {
  name        = "${var.project_name}-${var.environment}-ssm-endpoint-sg"
  description = "Allows private instances to access SSM VPC endpoints"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    description     = "HTTPS from App Tier"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-endpoint-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------------------------
# WRITE OUTPUTS TO AWS SSM PARAMETER STORE (SSM Coupling Setup)
# ------------------------------------------------------------------------------
resource "aws_ssm_parameter" "kms_key_arn" {
  name        = "/company-small/${var.environment}/security/kms_key_arn"
  type        = "String"
  value       = aws_kms_key.main.arn
  description = "KMS Key ARN for data encryption"
}

resource "aws_ssm_parameter" "alb_sg_id" {
  name        = "/company-small/${var.environment}/security/alb_sg_id"
  type        = "String"
  value       = aws_security_group.alb.id
  description = "ALB Security Group ID"
}

resource "aws_ssm_parameter" "app_sg_id" {
  name        = "/company-small/${var.environment}/security/app_sg_id"
  type        = "String"
  value       = aws_security_group.app.id
  description = "Application tier Security Group ID"
}

resource "aws_ssm_parameter" "data_sg_id" {
  name        = "/company-small/${var.environment}/security/data_sg_id"
  type        = "String"
  value       = aws_security_group.data.id
  description = "Data tier Security Group ID"
}
