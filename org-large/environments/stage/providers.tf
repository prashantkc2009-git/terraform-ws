terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.primary_region
}

provider "aws" {
  alias  = "us_primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_primary"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us_failover"
  region = "us-west-2"
}

provider "aws" {
  alias  = "eu_failover"
  region = "eu-central-1"
}
