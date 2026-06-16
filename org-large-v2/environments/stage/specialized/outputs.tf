output "sagemaker_domain_id" {
  value       = module.sagemaker_hyperpod.domain_id
}

output "vpn_connection_id" {
  value       = module.hybrid_connectivity.vpn_connection_id
}
