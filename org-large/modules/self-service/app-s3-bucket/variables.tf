variable "app_name" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, stage, prod)"
}

variable "team" {
  type        = string
  description = "Team owning the bucket"
}

variable "bucket_suffix" {
  type        = string
  description = "Bucket name suffix (e.g. assets, logs, data)"
  default     = "assets"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encryption"
  default     = null
}

variable "enable_versioning" {
  type        = bool
  description = "Enable S3 versioning"
  default     = true
}
