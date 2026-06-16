output "nlb_dns_name" {
  value       = module.nlb.nlb_dns_name
  description = "App1 NLB DNS name"
}

output "ec2_public_ips" {
  value       = module.ec2.instance_public_ips
  description = "App1 EC2 public IPs (one per AZ)"
}

output "ec2_private_ips" {
  value       = module.ec2.instance_private_ips
  description = "App1 EC2 private IPs"
}

output "db_cluster_endpoint" {
  value       = module.aurora.db_cluster_endpoint
  description = "App1 Aurora writer endpoint"
}

output "s3_bucket_id" {
  value       = module.s3.bucket_id
  description = "App1 S3 bucket ID"
}
