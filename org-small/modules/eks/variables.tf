# ==============================================================================
# Module: eks
# File: variables.tf
# Description: Defines the input variables for the EKS module (Workload C).
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

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where EKS nodes and control plane elastic network interfaces will run."
}

variable "cluster_role_arn" {
  type        = string
  description = "The ARN of the IAM role for the EKS Cluster control plane."
}

variable "node_role_arn" {
  type        = string
  description = "The ARN of the IAM role for EKS worker nodes."
}

variable "kubernetes_version" {
  type        = string
  description = "Desired Kubernetes master version."
  default     = "1.29"
}

variable "on_demand_instance_types" {
  type        = list(string)
  description = "List of instance types for the on-demand node group."
  default     = ["t3.medium"]
}

variable "spot_instance_types" {
  type        = list(string)
  description = "List of instance types for the spot node group."
  default     = ["t3.medium"]
}

variable "on_demand_desired_size" {
  type        = number
  description = "Desired number of worker nodes in on-demand node group."
}

variable "on_demand_min_size" {
  type        = number
  description = "Minimum number of worker nodes in on-demand node group."
}

variable "on_demand_max_size" {
  type        = number
  description = "Maximum number of worker nodes in on-demand node group."
}

variable "enable_spot_nodes" {
  type        = bool
  description = "Whether to provision a secondary spot-backed node group."
  default     = false
}

variable "spot_desired_size" {
  type        = number
  description = "Desired number of worker nodes in spot node group."
  default     = 0
}

variable "spot_min_size" {
  type        = number
  description = "Minimum number of worker nodes in spot node group."
  default     = 0
}

variable "spot_max_size" {
  type        = number
  description = "Maximum number of worker nodes in spot node group."
  default     = 0
}
