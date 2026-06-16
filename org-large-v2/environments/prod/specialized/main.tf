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

module "sagemaker_hyperpod" {
  source             = "../../../modules/specialized/sagemaker-hyperpod"
  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  execution_role_arn = var.execution_role_arn
}

module "hybrid_connectivity" {
  source       = "../../../modules/specialized/hybrid-connectivity"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = var.vpc_id
  enable_bare_metal = var.enable_bare_metal
  subnet_id    = var.bare_metal_subnet_id
}
