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

module "aws_organization" {
  source       = "../../../modules/foundation/aws-organization"
  environment  = var.environment
  enable_scp   = true
  enable_govcloud = var.enable_govcloud
}

module "aws_cloud_wan" {
  source       = "../../../modules/foundation/aws-cloud-wan"
  environment  = var.environment
  project_name = var.project_name
}

module "aws_control_tower" {
  source         = "../../../modules/foundation/aws-control-tower"
  root_ou_id     = module.aws_organization.organization_id
  enable_guardrails = true
}
