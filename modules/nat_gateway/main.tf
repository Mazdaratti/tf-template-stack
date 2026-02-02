############################################
# Elastic IPs (create or reuse)
############################################

# Create one EIP per NAT key unless we are reusing existing allocation IDs.
resource "aws_eip" "nat" {
  for_each = local.nat_enabled && !local.reuse_eips ? toset(local.nat_keys) : toset([])

  domain = "vpc"

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${each.key}"
  })
}

############################################
# NAT Gateways
############################################

resource "aws_nat_gateway" "this" {
  for_each = local.nat_enabled ? toset(local.nat_keys) : toset([])

  # If reusing EIPs: use the provided allocation IDs (order must match nat_keys order).
  # If creating EIPs: use the created EIP IDs (keyed by nat key).
  allocation_id = local.reuse_eips ? var.reuse_eip_allocation_ids[index(local.nat_keys, each.key)] : aws_eip.nat[each.key].id

  # NAT must live in a PUBLIC subnet.
  # - per_az: use the public subnet in the same AZ as the route table key
  # - single: pick the first public subnet from the map values
  subnet_id = local.is_per_az ? var.public_subnet_ids_by_az[each.key] : values(var.public_subnet_ids_by_az)[0]

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-nat-${each.key}"
  })
}

############################################
# Routes: private route tables -> NAT
############################################

# Create routes only if enabled and create_routes=true
resource "aws_route" "private_default" {
  for_each = local.nat_enabled && var.create_routes ? var.private_route_table_ids_by_az : {}

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"

  # - per_az: route table key is the AZ name, NAT key is the same AZ name
  # - single: all route tables point to the single NAT gateway
  nat_gateway_id = local.is_per_az ? aws_nat_gateway.this[each.key].id : aws_nat_gateway.this["single"].id
}
