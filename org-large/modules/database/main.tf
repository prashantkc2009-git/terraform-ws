# ==============================================================================
# Module: database
# File: main.tf
# Description: Configures Aurora Global DB, DynamoDB Global Tables, and MSK.
# ==============================================================================

# 1. DB Subnet Group
resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.data_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

# 2. Aurora Global Database (Core Transactional - Workload A)
resource "aws_rds_global_cluster" "global_db" {
  global_cluster_identifier = "${var.project_name}-global-db"
  engine                    = "aurora-postgresql"
  engine_version            = "15.4"
  database_name             = "payments"
  storage_encrypted         = true
}

# Aurora Primary Cluster
resource "aws_rds_cluster" "primary" {
  cluster_identifier        = "${var.project_name}-${var.environment}-db-cluster"
  engine                    = aws_rds_global_cluster.global_db.engine
  engine_version            = aws_rds_global_cluster.global_db.engine_version
  global_cluster_identifier = aws_rds_global_cluster.global_db.id
  database_name             = aws_rds_global_cluster.global_db.database_name
  master_username           = "postgres"
  master_password           = "MockPasswordForValidationOnly123!" # In real deploy, this would be rotated via Secrets Manager
  db_subnet_group_name      = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids    = [var.data_tier_sg_id]
  storage_encrypted         = true
  kms_key_id                = var.kms_key_arn

  # Enable Write Forwarding for Secondary clusters to write to Primary
  # Enabled at global database / cluster-level setup
  enable_global_write_forwarding = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-cluster"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "primary_instances" {
  count              = 2
  identifier         = "${var.project_name}-${var.environment}-db-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class     = "db.r7g.xlarge"
  engine             = aws_rds_cluster.primary.engine
  engine_version     = aws_rds_cluster.primary.engine_version

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-instance-${count.index}"
    Environment = var.environment
  }
}

# 3. DynamoDB Global Table (Workload B - Serverless Session Store)
resource "aws_dynamodb_table" "sessions" {
  name             = "${var.project_name}-${var.environment}-sessions"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "SessionId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "SessionId"
    type = "S"
  }

  # Multi-region replication is managed via replica blocks in standard AWS provider resources.
  # For active-active multi-region DynamoDB, we declare replicas:
  replica {
    region_name = "eu-west-1"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-sessions-global"
    Environment = var.environment
  }
}

# 4. Amazon MSK (Kafka Event Streaming - Workload B)
resource "aws_msk_cluster" "event_stream" {
  cluster_name           = "${var.project_name}-${var.environment}-msk"
  kafka_version          = "3.4.0"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.m5.large"
    client_subnets  = var.data_subnet_ids
    security_groups = [var.data_tier_sg_id]
    storage_info {
      ebs_storage_info {
        volume_size = 100
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-msk"
    Environment = var.environment
  }
}
