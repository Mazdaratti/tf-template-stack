# Development Environment - Outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "azs" {
  description = "Availability zones used by the network module."
  value       = module.network.azs
}

output "public_subnet_ids" {
  description = "A list of IDs of public subnets (empty if none)"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "A list of IDs of private subnets (empty if none)"
  value       = module.network.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "A list of CIDRs of public subnets (empty if none)"
  value       = module.network.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "A list of CIDRs of private subnets (empty if none)"
  value       = module.network.private_subnet_cidrs
}

output "public_route_table_id" {
  description = "The ID of the public route table if created, otherwise null"
  value       = module.network.public_route_table_id
}

############################################
# AZ name keyed outputs (useful for NAT wiring)
############################################

output "private_route_table_ids_by_az" {
  description = "A map of AZ name =>private route table ID (empty if none)"
  value       = module.network.private_route_table_ids_by_az
}

output "public_subnet_ids_by_az" {
  description = "A map of AZ name =>public subnet ID (empty if none)"
  value       = module.network.public_subnet_ids_by_az
}

output "private_subnet_ids_by_az" {
  description = "A map of AZ name =>private subnet ID (empty if none)"
  value       = module.network.private_subnet_ids_by_az
}

############################################
# NAT Gateway
############################################

output "nat_gateway_ids" {
  description = "Map of NAT key => NAT Gateway ID. Keys are AZ names in per_az mode or 'single' in single mode."
  value       = module.nat_gateway.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Map of NAT key => public IP address of the NAT Gateway."
  value       = module.nat_gateway.nat_gateway_public_ips
}

output "nat_eip_allocation_ids" {
  description = "Map of NAT key => EIP allocation ID used by the NAT Gateway."
  value       = module.nat_gateway.eip_allocation_ids
}

############################################
# Gateway endpoints (S3, DynamoDB)
############################################

output "gateway_endpoints_ids" {
  description = "Map of service name => VPC Endpoint ID for gateway endpoints (S3, DynamoDB)."
  value       = module.vpc_gateway_endpoints.endpoint_ids
}

output "s3_gateway_endpoint_id" {
  description = "VPC Endpoint ID for S3 gateway endpoint (null if disabled)."
  value       = module.vpc_gateway_endpoints.s3_endpoint_id
}

output "dynamodb_gateway_endpoint_id" {
  description = "VPC Endpoint ID for DynamoDB gateway endpoint (null if disabled)."
  value       = module.vpc_gateway_endpoints.dynamodb_endpoint_id
}

############################################
# VPC Interface Endpoints (PrivateLink)
############################################

output "interface_endpoint_ids" {
  description = "Map of service name => VPC Endpoint ID for interface endpoints (PrivateLink)."
  value       = module.vpc_interface_endpoints.endpoint_ids
}

output "interface_endpoint_arns" {
  description = "Map of service name => VPC Endpoint ARN for interface endpoints (PrivateLink)."
  value       = module.vpc_interface_endpoints.endpoint_arns
}

output "interface_endpoint_dns_entries" {
  description = "Map of service name => list of DNS entries for interface endpoints (PrivateLink)."
  value       = module.vpc_interface_endpoints.dns_entries
}

output "enabled_interface_endpoint_services" {
  description = "Set of enabled interface endpoint service keys."
  value       = module.vpc_interface_endpoints.enabled_services
}

output "interface_endpoint_security_group_id" {
  description = "Security group ID created by the module (null here because SG is managed externally)."
  value       = module.vpc_interface_endpoints.security_group_id
}

############################################
# KMS (kms_keys module)
############################################

output "kms_key_arns" {
  description = "Map of KMS key name => key ARN."
  value       = module.kms_keys.key_arns
}

output "kms_key_ids" {
  description = "Map of KMS key name => key ID."
  value       = module.kms_keys.key_ids
}

output "kms_alias_names" {
  description = "Map of KMS key name => alias name."
  value       = module.kms_keys.alias_names
}

output "kms_keys" {
  description = "Map of KMS key name => object with key_arn, key_id, and alias_name."
  value       = module.kms_keys.keys
}

############################################
# S3 (s3_bucket module)
############################################

output "s3_logs_bucket_name" {
  description = "S3 bucket name for centralized logs (destination for access logging)."
  value       = module.s3_bucket_logs.bucket_name
}

output "s3_logs_bucket_arn" {
  description = "S3 bucket ARN for centralized logs."
  value       = module.s3_bucket_logs.bucket_arn
}

output "s3_app_bucket_name" {
  description = "S3 bucket name for application data (source bucket)."
  value       = module.s3_bucket_app.bucket_name
}

output "s3_app_bucket_arn" {
  description = "S3 bucket ARN for application data."
  value       = module.s3_bucket_app.bucket_arn
}

############################################
# Logging baseline (CloudWatch Log Groups)
############################################

output "logging_baseline_log_group_arns" {
  description = "Map of log group key => CloudWatch Log Group ARN created by logging_baseline."
  value       = module.logging_baseline.log_group_arns
}

output "vpc_flow_logs_log_group_arn" {
  description = "CloudWatch Log Group ARN for VPC Flow Logs (shared log group created by logging_baseline)."
  value       = module.logging_baseline.log_group_arns["vpc_flow_logs"]
}

############################################
# VPC Flow Logs
############################################

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log created for the dev VPC."
  value       = module.vpc_flow_logs.flow_log_id
}

output "vpc_flow_logs_iam_role_arn" {
  description = "ARN of the IAM role used by VPC Flow Logs."
  value       = module.vpc_flow_logs.iam_role_arn
}

############################################
# Route53 private zones
############################################

output "route53_private_zone_ids" {
  description = "Map of logical zone key => Route53 private hosted zone ID."
  value       = module.route53_private_zones.zone_ids
}

output "route53_private_zone_names" {
  description = "Map of logical zone key => Route53 private hosted zone DNS name."
  value       = module.route53_private_zones.zone_names
}

output "route53_private_record_fqdns" {
  description = "Map of '<zone_key>::<record_key>' => computed Route53 private record FQDN."
  value       = module.route53_private_zones.record_fqdns
}

############################################
# ECS Cluster
############################################

output "ecs_cluster_id" {
  description = "ID of the ECS cluster created for the dev environment."
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster created for the dev environment."
  value       = module.ecs_cluster.cluster_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster created for the dev environment."
  value       = module.ecs_cluster.cluster_name
}

output "ecs_capacity_providers" {
  description = "Set of capacity providers associated with the dev ECS cluster."
  value       = module.ecs_cluster.capacity_providers
}

output "ecs_default_capacity_provider_strategy" {
  description = "Default capacity provider strategy configured on the dev ECS cluster (null if not configured)."
  value       = module.ecs_cluster.default_capacity_provider_strategy
}

############################################
# ALB Ingress
############################################

output "alb_ingress_arn" {
  description = "ARN of the internal ALB created for the dev ingress baseline."
  value       = module.alb_ingress.alb_arn
}

output "alb_ingress_dns_name" {
  description = "DNS name of the internal ALB created for the dev ingress baseline."
  value       = module.alb_ingress.alb_dns_name
}

output "alb_ingress_zone_id" {
  description = "Canonical hosted zone ID of the internal ALB created for the dev ingress baseline."
  value       = module.alb_ingress.alb_zone_id
}

output "alb_ingress_security_group_id" {
  description = "Security group ID created for the dev ALB ingress baseline."
  value       = module.alb_ingress.security_group_id
}

output "alb_ingress_listener_arns" {
  description = "Map of listener key => listener ARN for the dev ALB ingress baseline."
  value       = module.alb_ingress.listener_arns
}

output "alb_ingress_target_group_arns" {
  description = "Map of target group key => target group ARN for the dev ALB ingress baseline."
  value       = module.alb_ingress.target_group_arns
}

output "alb_ingress_target_group_names" {
  description = "Map of target group key => target group name for the dev ALB ingress baseline."
  value       = module.alb_ingress.target_group_names
}
