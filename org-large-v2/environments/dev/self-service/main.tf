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

module "app_s3_bucket_example" {
  source       = "../../../modules/self-service/app-s3-bucket"
  app_name     = var.app_name
  environment  = var.environment
  team         = var.team
}
