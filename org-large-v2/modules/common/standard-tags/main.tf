locals {
  standard_tags = {
    System      = var.system
    Environment = var.environment
    Team        = var.team
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = var.module_name
    CreatedAt   = timestamp()
  }
}
