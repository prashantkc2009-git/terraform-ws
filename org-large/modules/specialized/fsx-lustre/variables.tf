variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for FSx"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs"
  default     = []
}

variable "storage_capacity" {
  type        = number
  description = "Storage capacity in GiB (min 1200)"
  default     = 1200
}

variable "deployment_type" {
  type        = string
  description = "FSx Lustre deployment type"
  default     = "SCRATCH_2"
}

variable "per_unit_storage_throughput" {
  type        = number
  description = "Throughput per unit of storage (MB/s/TiB)"
  default     = 200
}

variable "export_path" {
  type        = string
  description = "S3 path for data export"
  default     = null
}

variable "import_path" {
  type        = string
  description = "S3 path for data import"
  default     = null
}

variable "imported_file_chunk_size" {
  type        = number
  description = "Imported file chunk size in bytes"
  default     = 1024
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encryption"
  default     = null
}
