output "cluster_arn" {
  value       = aws_msk_cluster.main.arn
  description = "MSK Kafka Cluster ARN"
}

output "cluster_name" {
  value       = aws_msk_cluster.main.cluster_name
  description = "MSK Kafka Cluster name"
}

output "bootstrap_brokers" {
  value       = aws_msk_cluster.main.bootstrap_brokers
  description = "MSK bootstrap brokers string"
  sensitive   = true
}

output "zookeeper_connect_string" {
  value       = aws_msk_cluster.main.zookeeper_connect_string
  description = "MSK ZooKeeper connection string"
  sensitive   = true
}
