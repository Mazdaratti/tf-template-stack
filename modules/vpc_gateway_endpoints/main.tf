############################################
# Gateway VPC Endpoints (S3, DynamoDB)
############################################

resource "aws_vpc_endpoint" "gateway" {
  for_each = local.enabled_services

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Gateway"

  service_name = "com.amazonaws.${local.effective_region}.${each.key}"

  route_table_ids = var.route_table_ids

  # Policy is managed separately via aws_vpc_endpoint_policy
  # so that policies are only created when explicitly provided.
  # This keeps lifecycle management clearer and avoids null-policy ambiguity.

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-vpce-gateway-${each.key}"
  })
}

############################################
# Optional endpoint policies
############################################

# Create endpoint policies only for services where a policy
# JSON document was explicitly provided by the caller.
#
# This avoids attaching null/default policies and keeps the
# module behavior predictable and reusable across projects.

resource "aws_vpc_endpoint_policy" "gateway" {
  for_each = {
    for svc, json in var.endpoint_policy_json :
    svc => json
    if contains(local.enabled_services, svc)
  }

  vpc_endpoint_id = aws_vpc_endpoint.gateway[each.key].id
  policy          = each.value
}

