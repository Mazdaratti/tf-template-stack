############################################
# Gateway VPC Endpoints (S3, DynamoDB)
############################################

resource "aws_vpc_endpoint" "gateway" {
  for_each = local.enabled_services

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Gateway"

  service_name = "com.amazonaws.${local.effective_region}.${each.key}"

  route_table_ids = var.route_table_ids

  # Optional endpoint policy per service (if provided)
  policy = lookup(var.endpoint_policy_json, each.key, null)

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-vpce-gateway-${each.key}"
  })
}
