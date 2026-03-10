############################################
# Outputs
############################################

############################################
# ECS service identity
############################################

output "service_id" {
  description = "ID of the ECS service."
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ARN of the ECS service."
  value       = aws_ecs_service.this.arn
}

############################################
# Task definition identity
############################################

output "task_definition_arn" {
  description = "ARN of the ECS task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Family of the ECS task definition."
  value       = aws_ecs_task_definition.this.family
}

############################################
# Security group
############################################

output "security_group_id" {
  description = "Security group ID created for the ECS service."
  value       = aws_security_group.service.id
}

############################################
# IAM roles
############################################

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role."
  value       = aws_iam_role.task.arn
}

############################################
# CloudWatch log group
############################################

output "log_group_name" {
  description = "Name of the module-managed CloudWatch Log Group (null when logging is disabled)."
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}

output "log_group_arn" {
  description = "ARN of the module-managed CloudWatch Log Group (null when logging is disabled)."
  value       = try(aws_cloudwatch_log_group.this[0].arn, null)
}
