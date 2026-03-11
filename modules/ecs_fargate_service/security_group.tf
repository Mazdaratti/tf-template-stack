############################################
# Service security group (no inline rules)
############################################
#
# Why separate rule resources?
# - Keeps security group lifecycle stable.
# - Avoids inline rule deprecations/pitfalls.
# - Keeps least-privilege ingress intent explicit.
############################################

resource "aws_security_group" "service" {
  name        = "${local.service_name}-sg"
  description = "Security group for the ECS Fargate service"
  vpc_id      = var.vpc_id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.service_name}-sg"
    }
  )
}

############################################
# Ingress rules from source security groups
############################################
#
# v1 keeps ingress least-privilege and SG-based.
# Each allowed source security group gets one
# dedicated rule to the effective service port.
############################################

resource "aws_vpc_security_group_ingress_rule" "from_source_sg" {
  for_each = toset(var.ingress_source_security_group_ids)

  security_group_id            = aws_security_group.service.id
  ip_protocol                  = "tcp"
  from_port                    = local.load_balancer_container_port
  to_port                      = local.load_balancer_container_port
  referenced_security_group_id = each.value

  description = "Allow application traffic from security group ${each.value} to port ${local.load_balancer_container_port}"
}

############################################
# Egress rules
############################################
#
# Keep outbound access simple in v1.
# One rule is created per allowed IPv4 CIDR.
############################################

resource "aws_vpc_security_group_egress_rule" "to_cidr" {
  for_each = toset(var.egress_cidr_ipv4)

  security_group_id = aws_security_group.service.id
  ip_protocol       = "-1"
  cidr_ipv4         = each.value

  description = "Allow outbound traffic from service to ${each.value}"
}
