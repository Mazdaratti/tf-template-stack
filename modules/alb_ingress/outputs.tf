############################################
# Outputs
############################################

############################################
# ALB identity and routing outputs
############################################

output "alb_id" {
  description = "ID of the Application Load Balancer."
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_name" {
  description = "Name of the Application Load Balancer."
  value       = aws_lb.this.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer."
  value       = aws_lb.this.zone_id
}

############################################
# Security group output
############################################

output "security_group_id" {
  description = "Security group ID created for the Application Load Balancer."
  value       = aws_security_group.alb.id
}

############################################
# Listener and target group outputs
############################################

output "listener_arns" {
  description = "Map of listener key => listener ARN."
  value       = { for key, listener in aws_lb_listener.this : key => listener.arn }
}

output "target_group_arns" {
  description = "Map of target group key => target group ARN."
  value       = { for key, tg in aws_lb_target_group.this : key => tg.arn }
}

output "target_group_names" {
  description = "Map of target group key => target group name."
  value       = { for key, tg in aws_lb_target_group.this : key => tg.name }
}
