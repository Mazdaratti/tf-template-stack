############################################
# Outputs
############################################

############################################
# Log group names
#
# Map key = var.log_groups key
# Value   = created CloudWatch Log Group name
############################################

output "log_group_names" {
  description = "Map of log group names created by this module (keyed by log_groups map keys)."

  value = {
    for key, lg in aws_cloudwatch_log_group.this :
    key => lg.name
  }
}

############################################
# Log group ARNs
#
# Map key = var.log_groups key
# Value   = created CloudWatch Log Group ARN
############################################

output "log_group_arns" {
  description = "Map of log group ARNs created by this module (keyed by log_groups map keys)."

  value = {
    for key, lg in aws_cloudwatch_log_group.this :
    key => lg.arn
  }
}