# ==============================================================================
# Module: redis
# File: variables.tf
# Description: Defines the input variables for the Redis ElastiCache module.
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

variable "data_subnet_ids" {
  type        = list(string)
  description = "List of data subnet IDs where the Redis subnet group will map."
}

variable "data_sg_id" {
  type        = string
  description = "The security group ID of the database and storage tier."
}

variable "node_type" {
  type        = string
  description = "The cache node instance class."
  default     = "cache.t3.micro"
}

variable "num_cache_clusters" {
  type        = number
  description = "The number of cache clusters (nodes) in the replication group."
  default     = 1
}
