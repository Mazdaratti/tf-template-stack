############################################
# Outputs
############################################

############################################
# Cluster identity
############################################

output "cluster_id" {
  description = "ID of the ECS cluster."
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

############################################
# Capacity providers
############################################

output "capacity_providers" {
  description = "Set of capacity providers associated with the ECS cluster."
  value       = toset(aws_ecs_cluster_capacity_providers.this.capacity_providers)
}

output "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy configured for the ECS cluster (null if not configured)."
  value = (
    length(aws_ecs_cluster_capacity_providers.this.default_capacity_provider_strategy) == 0
    ? null
    : [
      for s in aws_ecs_cluster_capacity_providers.this.default_capacity_provider_strategy : {
        capacity_provider = s.capacity_provider
        weight            = s.weight
        base              = try(s.base, null)
      }
    ]
  )
}
