output "s3_bucket_id" {
  value       = module.s3_bucket.bucket_id
  description = "The name/ID of the S3 bucket created for App 3"
}

output "aurora_cluster_endpoint" {
  value       = module.aurora_database.db_cluster_endpoint
  description = "The connection endpoint for the App 3 Aurora Cluster"
}

output "nlb_dns_name" {
  value       = aws_lb.nlb.dns_name
  description = "The DNS name of the Network Load Balancer for App 3"
}

output "vm_instance_ids" {
  value       = aws_instance.vm[*].id
  description = "The IDs of the App 3 VM instances"
}
