terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.primary_region
}

module "vpc_base" {
  source               = "../../../modules/shared/vpc-base"
  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  data_subnet_cidrs    = var.data_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "kms" {
  source       = "../../../modules/shared/kms-multi-region-key"
  environment  = var.environment
  project_name = var.project_name
}

module "observability" {
  source       = "../../../modules/shared/observability"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = module.vpc_base.vpc_id
}

module "eks_cluster_blueprint" {
  source             = "../../../modules/shared/eks-cluster-blueprint"
  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = module.vpc_base.vpc_id
  private_subnet_ids = module.vpc_base.private_subnet_ids
  private_eks_sg_id  = module.vpc_base.private_eks_sg_id
}

module "aurora_global_database" {
  source          = "../../../modules/shared/aurora-global-database"
  environment     = var.environment
  project_name    = var.project_name
  vpc_id          = module.vpc_base.vpc_id
  data_subnet_ids = module.vpc_base.data_subnet_ids
  data_tier_sg_id = module.vpc_base.data_tier_sg_id
  kms_key_arn     = module.kms.kms_key_arn
  database_name   = var.aurora_database_name
  master_password = var.aurora_master_password
}

module "dynamodb_global_table" {
  source          = "../../../modules/shared/dynamodb-global-table"
  environment     = var.environment
  project_name    = var.project_name
  table_name      = "sessions"
  hash_key        = "SessionId"
  attributes = [
    { name = "SessionId", type = "S" }
  ]
  replica_regions = var.environment == "prod" ? ["eu-west-1"] : []
  kms_key_arn     = module.kms.kms_key_arn
}

module "msk_cluster" {
  source          = "../../../modules/shared/msk-cluster"
  environment     = var.environment
  project_name    = var.project_name
  data_subnet_ids = module.vpc_base.data_subnet_ids
  data_tier_sg_id = module.vpc_base.data_tier_sg_id
  kms_key_arn     = module.kms.kms_key_arn
}

module "waf_canary" {
  source       = "../../../modules/shared/waf-canary"
  environment  = var.environment
  project_name = var.project_name
}

module "state_backend" {
  source       = "../../../modules/shared/terraform-state-backend"
  environment  = var.environment
  project_name = var.project_name
}

module "data_lifecycle" {
  source               = "../../../modules/shared/data-lifecycle"
  environment          = var.environment
  project_name         = var.project_name
  log_archive_bucket_id = module.observability.log_archive_bucket_id
  kms_key_arn          = module.kms.kms_key_arn
}
