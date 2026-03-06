############################################
# Outputs
############################################
#
# These outputs help users quickly verify
# what was created by the module.
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
  description = "Default capacity provider strategy (null when not configured)."
  value       = module.ecs_cluster.default_capacity_provider_strategy
}
