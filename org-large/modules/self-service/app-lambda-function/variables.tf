variable "app_name" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "function_name" {
  type        = string
  description = "Lambda function name (suffix)"
}

variable "package_path" {
  type        = string
  description = "Path to Lambda deployment package ZIP"
}

variable "handler" {
  type        = string
  description = "Lambda handler (e.g. index.handler)"
  default     = "index.handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "nodejs20.x"
}

variable "timeout" {
  type        = number
  description = "Lambda timeout in seconds"
  default     = 30
}

variable "memory_size" {
  type        = number
  description = "Lambda memory in MB"
  default     = 128
}

variable "source_code_hash" {
  type        = string
  description = "Base64-encoded SHA256 hash of the package"
  default     = null
}

variable "publish" {
  type        = bool
  description = "Publish a new version on each update"
  default     = false
}

variable "subnet_ids" {
  type        = list(string)
  description = "VPC subnet IDs for Lambda"
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for Lambda VPC config"
  default     = []
}

variable "permissions_boundary_arn" {
  type        = string
  description = "IAM permissions boundary ARN"
  default     = null
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the Lambda"
  default     = {}
}
