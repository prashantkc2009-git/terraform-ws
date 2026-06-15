# ==============================================================================
# Environment: prod
# File: variables.tf
# Description: Defines configuration parameters overrideable for the prod
#              environment.
# ==============================================================================

variable "aws_region" {
  type        = string
  description = "The target AWS region for deployment."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "The deployment environment name."
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "The project name identifier."
  default     = "company-small"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the zone/cert."
  default     = "company-small.io"
}

variable "single_nat_gateway" {
  type        = bool
  description = "If true, configures a single NAT GW for cost containment."
  default     = false # Multi NAT GW in production
}

# ------------------------------------------------------------------------------
# COMPUTE LAYER CONFIGURATION (PROD OVERRIDES)
# ------------------------------------------------------------------------------

# Workload A (Legacy Monolith)
variable "ec2_legacy_instance_type" {
  type        = string
  description = "The instance type of the active EC2 legacy monolith."
  default     = "t3.medium"
}

variable "ec2_legacy_create_standby" {
  type        = bool
  description = "Whether to create a pilot light standby node."
  default     = true # Active + Standby configuration
}

# Workload B (ASG API)
variable "asg_instance_type" {
  type        = string
  description = "The instance type of the API workers in the ASG."
  default     = "t3.large"
}

variable "asg_min_size" {
  type        = number
  description = "Minimum size of the ASG."
  default     = 2
}

variable "asg_max_size" {
  type        = number
  description = "Maximum size of the ASG."
  default     = 6
}

variable "asg_desired_size" {
  type        = number
  description = "Desired capacity of the ASG."
  default     = 2
}

# Workload C (EKS Cluster)
variable "eks_on_demand_instance_types" {
  type        = list(string)
  description = "Instance types for the EKS on-demand node group."
  default     = ["t3.medium"]
}

variable "eks_on_demand_desired_size" {
  type        = number
  description = "Desired number of worker nodes in on-demand node group."
  default     = 3
}

variable "eks_on_demand_min_size" {
  type        = number
  description = "Minimum number of worker nodes in on-demand node group."
  default     = 2
}

variable "eks_on_demand_max_size" {
  type        = number
  description = "Maximum number of worker nodes in on-demand node group."
  default     = 4
}

variable "eks_enable_spot_nodes" {
  type        = bool
  description = "Whether to provision a secondary spot-backed node group."
  default     = true
}

variable "eks_spot_desired_size" {
  type        = number
  description = "Desired number of worker nodes in spot node group."
  default     = 2
}

variable "eks_spot_min_size" {
  type        = number
  description = "Minimum number of worker nodes in spot node group."
  default     = 1
}

variable "eks_spot_max_size" {
  type        = number
  description = "Maximum number of worker nodes in spot node group."
  default     = 3
}

# Data Stores & Backups
variable "rds_instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.medium"
}

variable "rds_multi_az" {
  type        = bool
  description = "Enable Multi-AZ RDS."
  default     = true
}

variable "rds_allocated_storage" {
  type        = number
  description = "RDS allocated storage in GB."
  default     = 20
}

variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis node instance class."
  default     = "cache.t3.small"
}

variable "redis_num_cache_clusters" {
  type        = number
  description = "Number of cache nodes in Redis group."
  default     = 2
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain daily backups."
  default     = 35
}
