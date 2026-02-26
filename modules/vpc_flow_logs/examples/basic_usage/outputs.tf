############################################
# Outputs
############################################

##########################################
# 1. Flow Log
##########################################

output "flow_log_id" {
  description = "ID of the VPC Flow Log."
  value       = module.vpc_flow_logs.flow_log_id
}

##########################################
# 2. IAM Role
##########################################

output "iam_role_arn" {
  description = "ARN of the IAM role used by VPC Flow Logs."
  value       = module.vpc_flow_logs.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by VPC Flow Logs."
  value       = module.vpc_flow_logs.iam_role_name
}