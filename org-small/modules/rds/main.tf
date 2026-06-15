# ==============================================================================
# Module: rds
# File: main.tf
# Description: Provisions the Multi-AZ RDS PostgreSQL database instance using
#              gp3 KMS-encrypted storage.
# ==============================================================================

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids  = var.data_subnet_ids
  description = "RDS Database Subnet Group"

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "postgres" {
  identifier                  = "${var.project_name}-${var.environment}-postgres"
  engine                      = "postgres"
  engine_version              = "15.7"
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = 100
  storage_type                = "gp3"
  storage_encrypted           = true
  kms_key_id                  = var.kms_key_arn
  multi_az                    = var.multi_az
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [var.data_sg_id]
  db_name                     = var.database_name
  username                    = var.master_username
  password                    = random_password.password.result
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  backup_retention_period     = var.environment == "prod" ? 35 : (var.environment == "staging" ? 14 : 7)
  skip_final_snapshot         = var.environment == "prod" ? false : true
  final_snapshot_identifier   = "${var.project_name}-${var.environment}-postgres-final-snapshot"
  deletion_protection         = var.environment == "prod" ? true : false

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
