############################################
# CloudWatch Log Groups
#
# This module creates a controlled set of shared log groups.
# Downstream modules (for example: vpc_flow_logs) can write into
# one of these pre-created log groups by referencing the outputs.
############################################

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.log_groups

  # Final name:
  #   <log_group_name_prefix>/<name_suffix>
  name = "${local.log_group_name_prefix}/${each.value.name_suffix}"

  # Retention:
  # - per-log-group override wins
  # - otherwise module-level default
  retention_in_days = try(each.value.retention_in_days, var.retention_in_days)

  # Encryption:
  # - per-log-group override wins
  # - otherwise module-level default
  kms_key_id = coalesce(try(each.value.kms_key_arn, null), var.kms_key_arn)

  tags = local.merged_tags
}