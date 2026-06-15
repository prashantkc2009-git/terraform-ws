# ==============================================================================
# Environment: prod
# File: variables.tf
# Description: Defines input parameters for the Production environment.
# ==============================================================================

variable "aws_region" {
  type        = string
  description = "The AWS Region to deploy all infrastructure into."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "The name of the target environment."
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "The naming prefix applied to resources."
  default     = "company-mid"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC class A/B block range."
  default     = "10.30.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Target zones to isolate resources."
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public network allocations."
  default     = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private EKS/compute network allocations."
  default     = ["10.30.16.0/20", "10.30.32.0/20", "10.30.48.0/20"]
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "Secure backend data tier allocations."
  default     = ["10.30.64.0/22", "10.30.68.0/22", "10.30.72.0/22"]
}

variable "endpoint_subnet_cidrs" {
  type        = list(string)
  description = "VPC PrivateLink endpoint allocations."
  default     = ["10.30.96.0/24", "10.30.97.0/24", "10.30.98.0/24"]
}

variable "tgw_subnet_cidrs" {
  type        = list(string)
  description = "TGW attachment allocations."
  default     = ["10.30.112.0/28", "10.30.112.16/28", "10.30.112.32/28"]
}

variable "github_org" {
  type        = string
  description = "GitHub org name for workflow identity verification."
  default     = "company-mid-org"
}
