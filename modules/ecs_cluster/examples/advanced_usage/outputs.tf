############################################
# Outputs
############################################
#
# These outputs show the same core outputs as basic_usage
# plus a quick check that the advanced log resource was used.
############################################

output "cluster_id" {
  description = "ID of the ECS cluster."
  value       = module.ecs_cluster.cluster_id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = module.ecs_cluster.cluster_arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = module.ecs_cluster.cluster_name
}

output "capacity_providers" {
  description = "Capacity providers associated with the ECS cluster."
  value       = module.ecs_cluster.capacity_providers
}

output "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy used by the cluster."
  value       = module.ecs_cluster.default_capacity_provider_strategy
}

output "ecs_exec_log_group" {
  description = "CloudWatch Log Group used for ECS Exec override logging."
  value       = aws_cloudwatch_log_group.ecs_exec.name
}
