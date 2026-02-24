############################################
# Outputs
############################################

output "log_group_names" {
  description = "Created log group names (keyed by log_groups keys)."
  value       = module.logging_baseline.log_group_names
}

output "log_group_arns" {
  description = "Created log group ARNs (keyed by log_groups keys)."
  value       = module.logging_baseline.log_group_arns
}