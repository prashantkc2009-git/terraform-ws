variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the private app tier"
}

variable "private_eks_sg_id" {
  type        = string
  description = "Security Group ID for EKS cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes Version"
  default     = "1.28"
}
