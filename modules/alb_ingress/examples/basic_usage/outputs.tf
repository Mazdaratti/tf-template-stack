############################################
# Outputs
############################################
#
# These outputs help users quickly verify
# what was created by the example.
############################################

output "alb_arn" {
  description = "ARN of the ALB created by the example."
  value       = module.alb_ingress.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB created by the example."
  value       = module.alb_ingress.alb_dns_name
}

output "security_group_id" {
  description = "Security group ID created for the ALB."
  value       = module.alb_ingress.security_group_id
}

output "listener_arns" {
  description = "Map of listener key => listener ARN."
  value       = module.alb_ingress.listener_arns
}

output "target_group_arns" {
  description = "Map of target group key => target group ARN."
  value       = module.alb_ingress.target_group_arns
}
