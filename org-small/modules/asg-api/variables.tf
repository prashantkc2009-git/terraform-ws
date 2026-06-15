# ==============================================================================
# Module: asg-api
# File: variables.tf
# Description: Defines the input variables for the auto-scaled API module (Workload B).
# ==============================================================================

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, staging, prod)."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs where the ALB will reside."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where the instances will run."
}

variable "app_sg_id" {
  type        = string
  description = "The Security Group ID of the private application tier (used by launch template)."
}

variable "alb_sg_id" {
  type        = string
  description = "The Security Group ID of the public ALB."
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key for launch template volume encryption."
}

variable "iam_instance_profile_name" {
  type        = string
  description = "The name of the IAM instance profile for instances."
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ACM Certificate ARN for HTTPS listener configuration."
}

variable "route53_zone_id" {
  type        = string
  description = "The Route 53 public hosted zone ID."
}

variable "domain_name" {
  type        = string
  description = "The root domain name or active subdomain prefix."
}

variable "instance_type" {
  type        = string
  description = "The instance type for the API workers."
  default     = "t3.large"
}

variable "asg_min_size" {
  type        = number
  description = "Minimum size of the Auto Scaling Group."
}

variable "asg_max_size" {
  type        = number
  description = "Maximum size of the Auto Scaling Group."
}

variable "asg_desired_size" {
  type        = number
  description = "Desired capacity of the Auto Scaling Group."
}

variable "target_cpu_utilization" {
  type        = number
  description = "The target CPU utilization percentage for dynamic scaling."
  default     = 60
}
