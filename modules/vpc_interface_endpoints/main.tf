############################################
# Optional security group (no inline rules)
############################################

# The security group itself is created without inline rules.
# Rules are managed as separate resources so they can be extended
# or overridden later from envs/* without replacing the SG.
#
# This security group is created only if var.create_security_group is set to true.
# Otherwise, the module will not create a security group and will instead rely on
# the security group IDs passed in via var.security_group_ids.
resource "aws_security_group" "endpoint" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.project_name}-${var.environment}-endpoint-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = var.vpc_id

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-endpoint-sg"
  })
}

############################################
# Default security group rules (baseline)
############################################

# Minimal default ingress:
# HTTPS is required for all AWS interface endpoints.
# This rule is intentionally permissive and meant to be hardened 
# (e.g. by restricting source CIDRs or adding specific rules for certain endpoints)
# in envs/dev by adding additional rules.
resource "aws_vpc_security_group_ingress_rule" "https" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.endpoint[0].id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"

  description = "Allow HTTPS traffic to interface endpoints"
}

# Default egress: required for endpoint ENIs to talk to AWS services.
resource "aws_vpc_security_group_egress_rule" "all" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.endpoint[0].id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Allow all outbound traffic from interface endpoints"
}

############################################
# Interface VPC endpoints
############################################

# Create an interface VPC endpoint for each enabled service
resource "aws_vpc_endpoint" "interface" {
  for_each = local.enabled_interface_endpoints

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"

  # Region-specific service name, derived in locals.tf
  service_name = local.service_names[each.key]

  # Interface endpoints are placed into subnets (usually private)
  subnet_ids = var.subnet_ids

  # Prefer externally managed SGs if provided.
  # Otherwise fall back to the module-created SG.
  security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : (var.create_security_group ? [aws_security_group.endpoint[0].id] : [])

  # Private DNS is enabled per endpoint (default = true)
  private_dns_enabled = each.value.private_dns_enabled

  # Optional endpoint policy (injected from envs/dev)
  policy = lookup(var.endpoint_policy_json, each.key, null)

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-vpce-interface-${each.key}"
  })
}

