output "vpn_connection_id" {
  value       = aws_vpn_connection.on_prem_vpn.id
  description = "VPN Connection ID"
}

output "vpn_connection_tunnel1_address" {
  value       = aws_vpn_connection.on_prem_vpn.tunnel1_address
  description = "VPN Tunnel 1 address"
  sensitive   = true
}

output "vpn_connection_tunnel2_address" {
  value       = aws_vpn_connection.on_prem_vpn.tunnel2_address
  description = "VPN Tunnel 2 address"
  sensitive   = true
}

output "legacy_instance_id" {
  value       = var.enable_bare_metal ? aws_instance.legacy_mainframe_connector[0].id : null
  description = "Legacy bare metal instance ID"
}

output "customer_gateway_id" {
  value       = aws_customer_gateway.on_prem.id
  description = "Customer Gateway ID"
}
