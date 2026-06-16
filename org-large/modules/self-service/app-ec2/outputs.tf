output "instance_ids" {
  value       = aws_instance.main[*].id
  description = "EC2 instance IDs"
}

output "instance_public_ips" {
  value       = aws_instance.main[*].public_ip
  description = "EC2 instance public IPs"
}

output "instance_private_ips" {
  value       = aws_instance.main[*].private_ip
  description = "EC2 instance private IPs"
}

output "instance_subnet_ids" {
  value       = aws_instance.main[*].subnet_id
  description = "Subnet IDs (one per AZ)"
}

output "ec2_sg_id" {
  value       = aws_security_group.ec2.id
  description = "EC2 security group ID"
}

output "iam_role_arn" {
  value       = aws_iam_role.ec2.arn
  description = "EC2 IAM role ARN"
}
