variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "github_org" {
  type        = string
  description = "GitHub organization name"
  default     = "company"
}

variable "repo_name" {
  type        = string
  description = "GitHub repository name"
}

variable "enable_apply_role" {
  type        = bool
  description = "Create the Terraform Apply role (main branch only)"
  default     = true
}

variable "allowed_regions" {
  type        = list(string)
  description = "Regions allowed for Terraform Apply actions"
  default     = ["us-east-1", "us-west-2", "eu-west-1", "eu-central-1"]
}
