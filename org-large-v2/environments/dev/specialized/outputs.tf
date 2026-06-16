output "sagemaker_domain_id" {
  value       = module.sagemaker_hyperpod.domain_id
  description = "SageMaker Domain ID"
}

output "vpn_connection_id" {
  value       = module.hybrid_connectivity.vpn_connection_id
  description = "VPN Connection ID"
}
