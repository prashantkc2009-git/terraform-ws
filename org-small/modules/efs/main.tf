# ==============================================================================
# Module: efs
# File: main.tf
# Description: Provisions the Elastic Throughput EFS shared filesystem with
#              mount targets in the private data subnets.
# ==============================================================================

resource "aws_efs_file_system" "main" {
  creation_token = "${var.project_name}-${var.environment}-efs"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  # Elastic Throughput mode prevents bottleneck latency spikes
  throughput_mode = "elastic"

  tags = {
    Name        = "${var.project_name}-${var.environment}-efs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_efs_mount_target" "main" {
  count           = length(var.data_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.data_subnet_ids[count.index]
  security_groups = [var.data_sg_id]
}
