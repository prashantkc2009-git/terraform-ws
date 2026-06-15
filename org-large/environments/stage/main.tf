# ==============================================================================
# Environment: stage
# File: main.tf
# Description: Orchestrates modular infrastructure for company-large in stage.
# ==============================================================================

module "organizations" {
  source      = "../../modules/organizations"
  environment = var.environment
  enable_scp  = false
}

module "security" {
  source       = "../../modules/security"
  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.primary_region
}

module "networking" {
  source               = "../../modules/networking"
  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  data_subnet_cidrs    = var.data_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "database" {
  source          = "../../modules/database"
  environment     = var.environment
  project_name    = var.project_name
  vpc_id          = module.networking.vpc_id
  data_subnet_ids = module.networking.data_subnet_ids
  data_tier_sg_id = module.networking.data_tier_sg_id
  kms_key_arn     = module.security.kms_key_arn
}

module "compute" {
  source             = "../../modules/compute"
  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  private_eks_sg_id  = module.networking.private_eks_sg_id
}

module "observability" {
  source       = "../../modules/observability"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}
