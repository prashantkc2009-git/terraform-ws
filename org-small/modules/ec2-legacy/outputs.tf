# ==============================================================================
# Module: ec2-legacy
# File: outputs.tf
# Description: Defines the outputs of the legacy EC2 monolith module.
# ==============================================================================

output "active_instance_id" {
  value       = aws_instance.active.id
  description = "The ID of the active EC2 instance."
}

output "active_instance_private_ip" {
  value       = aws_instance.active.private_ip
  description = "The private IP address of the active EC2 instance."
}

output "standby_instance_id" {
  value       = var.create_standby ? aws_instance.standby[0].id : null
  description = "The ID of the standby EC2 instance, if created."
}

output "standby_instance_private_ip" {
  value       = var.create_standby ? aws_instance.standby[0].private_ip : null
  description = "The private IP address of the standby EC2 instance, if created."
}
