# ==============================================================================
# Environment: dev
# File: main.tf
# Description: Tiers modules to build out the full infrastructure for Dev.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Network Layer (Phase 1)
module "networking" {
  source             = "../../modules/networking"
  environment        = var.environment
  project_name       = var.project_name
  domain_name        = var.domain_name
  single_nat_gateway = var.single_nat_gateway
}

# 2. Security Layer (Phase 2)
module "security" {
  source       = "../../modules/security"
  environment  = var.environment
  project_name = var.project_name
  domain_name  = var.domain_name

  # Add explicit dependency since security uses SSM parameters written by networking
  depends_on = [module.networking]
}

# 3. Identity and Access Layer (Phase 3)
module "iam" {
  source       = "../../modules/iam"
  environment  = var.environment
  project_name = var.project_name
}

# 4. Compute Layer - Legacy Monolith (Workload A)
module "ec2_legacy" {
  source                    = "../../modules/ec2-legacy"
  project_name              = var.project_name
  environment               = var.environment
  private_subnet_ids        = module.networking.private_subnet_ids
  app_sg_id                 = module.security.app_sg_id
  kms_key_arn               = module.security.kms_key_arn
  iam_instance_profile_name = module.iam.ec2_legacy_profile_name
  instance_type_active      = var.ec2_legacy_instance_type
  create_standby            = var.ec2_legacy_create_standby
}

# 5. Compute Layer - Auto-Scaled API (Workload B)
module "asg_api" {
  source                    = "../../modules/asg-api"
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_subnet_ids        = module.networking.private_subnet_ids
  app_sg_id                 = module.security.app_sg_id
  alb_sg_id                 = module.security.alb_sg_id
  kms_key_arn               = module.security.kms_key_arn
  iam_instance_profile_name = module.iam.asg_api_profile_name
  acm_certificate_arn       = module.networking.acm_certificate_arn
  route53_zone_id           = module.networking.route53_zone_id
  domain_name               = var.domain_name
  instance_type             = var.asg_instance_type
  asg_min_size              = var.asg_min_size
  asg_max_size              = var.asg_max_size
  asg_desired_size          = var.asg_desired_size
}

# 6. Compute Layer - EKS Cluster (Workload C)
module "eks" {
  source                   = "../../modules/eks"
  project_name             = var.project_name
  environment              = var.environment
  vpc_id                   = module.networking.vpc_id
  private_subnet_ids       = module.networking.private_subnet_ids
  cluster_role_arn         = module.iam.eks_cluster_role_arn
  node_role_arn            = module.iam.eks_node_role_arn
  on_demand_instance_types = var.eks_on_demand_instance_types
  on_demand_desired_size   = var.eks_on_demand_desired_size
  on_demand_min_size       = var.eks_on_demand_min_size
  on_demand_max_size       = var.eks_on_demand_max_size
  enable_spot_nodes        = var.eks_enable_spot_nodes
}

# 7. S3 Buckets
module "s3" {
  source       = "../../modules/s3"
  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn
}

# 8. EFS Shared Filesystem
module "efs" {
  source          = "../../modules/efs"
  project_name    = var.project_name
  environment     = var.environment
  data_subnet_ids = module.networking.data_subnet_ids
  data_sg_id      = module.security.data_sg_id
  kms_key_arn     = module.security.kms_key_arn
}

# 9. RDS PostgreSQL Database
module "rds" {
  source            = "../../modules/rds"
  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  data_subnet_ids   = module.networking.data_subnet_ids
  data_sg_id        = module.security.data_sg_id
  kms_key_arn       = module.security.kms_key_arn
  instance_class    = var.rds_instance_class
  multi_az          = var.rds_multi_az
  allocated_storage = var.rds_allocated_storage
}

# 10. Redis Cache
module "redis" {
  source             = "../../modules/redis"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  data_subnet_ids    = module.networking.data_subnet_ids
  data_sg_id         = module.security.data_sg_id
  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_clusters
}

# 11. Secrets Manager
module "secrets" {
  source       = "../../modules/secrets"
  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn
  db_username  = module.rds.db_instance_username
  db_password  = module.rds.db_instance_password
}

# 12. Backup Services
module "backup" {
  source          = "../../modules/backup"
  project_name    = var.project_name
  environment     = var.environment
  backup_role_arn = module.iam.backup_role_arn
  retention_days  = var.backup_retention_days
}

# 13. CloudWatch Monitoring
module "monitoring" {
  source         = "../../modules/monitoring"
  project_name   = var.project_name
  environment    = var.environment
  asg_name       = module.asg_api.asg_name
  db_instance_id = "${var.project_name}-${var.environment}-postgres"
}


