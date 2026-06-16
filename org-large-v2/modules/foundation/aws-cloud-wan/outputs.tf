output "global_network_id" {
  value       = aws_networkmanager_global_network.main.id
  description = "Cloud WAN Global Network ID"
}

output "core_network_id" {
  value       = aws_networkmanager_core_network.core.id
  description = "Cloud WAN Core Network ID"
}

output "core_network_arn" {
  value       = aws_networkmanager_core_network.core.arn
  description = "Cloud WAN Core Network ARN"
}
