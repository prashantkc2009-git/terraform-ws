variable "admin_arns" {
  type        = list(string)
  description = "ARNs of Lake Formation administrators"
  default     = []
}

variable "database_permissions" {
  type = map(object({
    principal       = string
    permissions     = list(string)
    database_name   = string
  }))
  description = "Database-level Lake Formation permissions"
  default     = {}
}

variable "table_permissions" {
  type = map(object({
    principal       = string
    permissions     = list(string)
    database_name   = string
    table_name      = string
  }))
  description = "Table-level Lake Formation permissions"
  default     = {}
}

variable "cell_level_permissions" {
  type = map(object({
    principal               = string
    permissions             = list(string)
    database_name           = string
    table_name              = string
    column_names            = list(string)
    row_filter_expression   = optional(string)
  }))
  description = "Cell-level (column + row) Lake Formation permissions for PII"
  default     = {}
}
