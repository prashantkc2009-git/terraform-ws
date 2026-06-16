resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.data_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_rds_global_cluster" "global_db" {
  global_cluster_identifier = "${var.project_name}-global-db"
  engine                    = "aurora-postgresql"
  engine_version            = "15.4"
  database_name             = var.database_name
  storage_encrypted         = true
}

resource "aws_rds_cluster" "primary" {
  cluster_identifier        = "${var.project_name}-${var.environment}-db-cluster"
  engine                    = aws_rds_global_cluster.global_db.engine
  engine_version            = aws_rds_global_cluster.global_db.engine_version
  global_cluster_identifier = aws_rds_global_cluster.global_db.id
  database_name             = aws_rds_global_cluster.global_db.database_name
  master_username           = var.master_username
  master_password           = var.master_password
  db_subnet_group_name      = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids    = [var.data_tier_sg_id]
  storage_encrypted         = true
  kms_key_id                = var.kms_key_arn
  enable_global_write_forwarding = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-cluster"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "primary_instances" {
  count              = var.instance_count
  identifier         = "${var.project_name}-${var.environment}-db-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.primary.engine
  engine_version     = aws_rds_cluster.primary.engine_version

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-instance-${count.index}"
    Environment = var.environment
  }
}
