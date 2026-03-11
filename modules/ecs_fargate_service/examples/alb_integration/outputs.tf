############################################
# Outputs
############################################
#
# These outputs help users quickly verify
# what was created by the example.
############################################

output "alb_dns_name" {
  description = "DNS name of the example Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the example ALB target group."
  value       = aws_lb_target_group.app.arn
}

output "service_name" {
  description = "Name of the ECS service created by the module."
  value       = module.ecs_fargate_service.service_name
}

output "service_arn" {
  description = "ARN of the ECS service created by the module."
  value       = module.ecs_fargate_service.service_arn
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition created by the module."
  value       = module.ecs_fargate_service.task_definition_arn
}

output "service_security_group_id" {
  description = "Security group ID created for the ECS service."
  value       = module.ecs_fargate_service.security_group_id
}

output "log_group_name" {
  description = "CloudWatch Log Group name created for the ECS service."
  value       = module.ecs_fargate_service.log_group_name
}
