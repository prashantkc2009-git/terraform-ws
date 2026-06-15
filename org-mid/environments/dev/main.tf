# ==============================================================================
# Environment: dev
# File: main.tf
# Description: Instantiates foundational org-mid modules for the Dev environment.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "random" {
}

# 1. AWS Organization Layer
module "organizations" {
  source      = "../../modules/organizations"
  environment = var.environment
  enable_scp  = false
}

# 2. Networking Layer
module "networking" {
  source                = "../../modules/networking"
  environment           = var.environment
  project_name          = var.project_name
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  data_subnet_cidrs     = var.data_subnet_cidrs
  endpoint_subnet_cidrs = var.endpoint_subnet_cidrs
  tgw_subnet_cidrs      = var.tgw_subnet_cidrs
  tgw_id                = ""    # No TGW in dev; NAT Gateway provides outbound access
  enable_flow_logs      = false # Disabled Flow Logs in dev sandbox to avoid log destination ARN requirement
}

# 3. Security & KMS Layer
module "security" {
  source       = "../../modules/security"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
}

# 4. IAM & Roles Layer
module "iam" {
  source       = "../../modules/iam"
  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.aws_region
  github_org   = var.github_org
}

# 5. S3 Buckets Storage
module "s3" {
  source       = "../../modules/s3"
  environment  = var.environment
  project_name = var.project_name
  kms_key_arn  = module.security.kms_key_arn
}

# 6. Secrets Manager Layer
module "secrets" {
  source       = "../../modules/secrets"
  environment  = var.environment
  project_name = var.project_name
  kms_key_arn  = module.security.kms_key_arn
}
