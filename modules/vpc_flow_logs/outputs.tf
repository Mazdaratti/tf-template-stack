############################################
# Outputs
############################################

##########################################
# 1. Flow Log
##########################################

output "flow_log_id" {
  description = "ID of the VPC Flow Log."
  value       = aws_flow_log.this.id
}

##########################################
# 2. IAM Role
##########################################

output "iam_role_arn" {
  description = "ARN of the IAM role used by VPC Flow Logs."
  value       = aws_iam_role.this.arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by VPC Flow Logs."
  value       = aws_iam_role.this.name
}