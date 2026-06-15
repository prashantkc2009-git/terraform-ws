# ==============================================================================
# Module: networking
# File: variables.tf
# Description: Defines parameters for the org-mid network baseline.
# ==============================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod)."
}

variable "project_name" {
  type        = string
  description = "The name of the project to prefix or tag resources with."
  default     = "company-mid"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the custom VPC."
}

variable "availability_zones" {
  type        = list(string)
  description = "A list of availability zones to deploy the subnets across."
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnet tier (e.g., hosting public ALBs)."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private subnet tier (EKS platform, EKS customer, EKS internal)."
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the data subnet tier (Aurora, Redis, MSK)."
}

variable "endpoint_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for interface and gateway VPC Endpoints."
}

variable "tgw_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for Transit Gateway attachment subnets."
}

variable "tgw_id" {
  type        = string
  description = "The ID of the Transit Gateway. If empty, Transit Gateway attachments are disabled."
  default     = ""
}

variable "enable_flow_logs" {
  type        = bool
  description = "Flag to enable VPC Flow Logs."
  default     = true
}

variable "log_destination_arn" {
  type        = string
  description = "The ARN of the CloudWatch Log Group or S3 Bucket for Flow Logs."
  default     = ""
}
