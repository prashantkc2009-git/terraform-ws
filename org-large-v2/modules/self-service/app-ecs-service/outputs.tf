output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS cluster name"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.main.arn
  description = "ECS cluster ARN"
}

output "ecs_service_name" {
  value       = aws_ecs_service.main.name
  description = "ECS service name"
}

output "ecs_service_arn" {
  value       = aws_ecs_service.main.arn
  description = "ECS service ARN"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.main.arn
  description = "Task definition ARN"
}

output "target_group_arn" {
  value       = aws_lb_target_group.main.arn
  description = "ALB target group ARN"
}
