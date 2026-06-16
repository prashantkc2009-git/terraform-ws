resource "aws_fsx_lustre_filesystem" "main" {
  storage_capacity        = var.storage_capacity
  subnet_ids              = var.subnet_ids
  deployment_type         = var.deployment_type
  per_unit_storage_throughput = var.per_unit_storage_throughput
  export_path             = var.export_path
  import_path             = var.import_path
  imported_file_chunk_size = var.imported_file_chunk_size
  security_group_ids      = var.security_group_ids
  kms_key_id              = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-fsx-lustre"
    Environment = var.environment
  }
}
