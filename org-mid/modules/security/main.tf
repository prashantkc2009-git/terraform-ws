# ==============================================================================
# Module: security
# File: main.tf
# Description: Implements Security Groups tiering, KMS, and WAF base.
# ==============================================================================

# KMS Customer Managed Key
resource "aws_kms_key" "main" {
  description             = "Main Customer Managed Key for ${var.project_name}-${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = var.kms_key_rotation_enabled

  tags = {
    Name        = "${var.project_name}-${var.environment}-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}-key"
  target_key_id = aws_kms_key.main.key_id
}

# Security Groups (Section 4.3)
resource "aws_security_group" "edge" {
  name        = "${var.project_name}-${var.environment}-edge-sg"
  description = "Security group for public facing ALBs"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow TLS traffic from anywhere (viewer facing)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-edge-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for EKS worker nodes and compute instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from public ALB edge SG"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.edge.id]
  }

  ingress {
    description = "Allow internal VPC range traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "data" {
  name        = "${var.project_name}-${var.environment}-data-sg"
  description = "Security group for Aurora DB, Redis, and MSK"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow DB/Cache ingress from App SG"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-data-sg"
    Environment = var.environment
  }
}

# AWS WAF Web ACL (Simplified Sandbox configuration)
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-${var.environment}-waf-acl"
  description = "WAF for ${var.project_name}-${var.environment} edge endpoints"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf-metric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf-acl"
    Environment = var.environment
  }
}
