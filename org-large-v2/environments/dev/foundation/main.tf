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

module "network_firewall" {
  source       = "../../../modules/foundation/aws-network-firewall"
  environment  = var.environment
  project_name = var.project_name
  availability_zones = var.availability_zones
}
