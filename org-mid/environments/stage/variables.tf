# ==============================================================================
# Environment: stage
# File: variables.tf
# Description: Defines input parameters for the Staging environment.
# ==============================================================================

variable "aws_region" {
  type        = string
  description = "The AWS Region to deploy all infrastructure into."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "The name of the target environment."
  default     = "stage"
}

variable "project_name" {
  type        = string
  description = "The naming prefix applied to resources."
  default     = "company-mid"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC class A/B block range."
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Target zones to isolate resources."
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public network allocations."
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private EKS/compute network allocations."
  default     = ["10.20.16.0/20", "10.20.32.0/20"]
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "Secure backend data tier allocations."
  default     = ["10.20.64.0/22", "10.20.68.0/22"]
}

variable "endpoint_subnet_cidrs" {
  type        = list(string)
  description = "VPC PrivateLink endpoint allocations."
  default     = ["10.20.96.0/24", "10.20.97.0/24"]
}

variable "tgw_subnet_cidrs" {
  type        = list(string)
  description = "TGW attachment allocations."
  default     = ["10.20.112.0/28", "10.20.112.16/28"]
}

variable "github_org" {
  type        = string
  description = "GitHub org name for workflow identity verification."
  default     = "company-mid-org"
}
