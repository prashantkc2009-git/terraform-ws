output "filesystem_id" {
  value       = aws_fsx_lustre_filesystem.main.id
  description = "FSx Lustre file system ID"
}

output "filesystem_arn" {
  value       = aws_fsx_lustre_filesystem.main.arn
  description = "FSx Lustre file system ARN"
}

output "dns_name" {
  value       = aws_fsx_lustre_filesystem.main.dns_name
  description = "FSx Lustre DNS name"
}

output "mount_name" {
  value       = aws_fsx_lustre_filesystem.main.mount_name
  description = "FSx Lustre mount name"
}
