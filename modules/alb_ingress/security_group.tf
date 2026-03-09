############################################
# ALB Security Group (no inline rules)
############################################
#
# Why separate rule resources?
# - Keeps security group lifecycle stable.
# - Avoids inline rule deprecations/pitfalls.
# - Makes least-privilege rule composition explicit.
############################################

resource "aws_security_group" "alb" {
  name        = "${local.alb_name}-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.alb_name}-sg"
    }
  )
}

############################################
# Ingress rules from CIDRs
############################################
#
# For each listener port and each allowed CIDR, create
# one dedicated ingress rule:
#   (port x cidr) => one rule resource
#
# This keeps rule intent easy to read in Terraform state
# and in AWS console/API responses.
############################################

resource "aws_vpc_security_group_ingress_rule" "from_cidr_by_port" {
  for_each = {
    for pair in flatten([
      for port in local.listener_ports : [
        for cidr in var.ingress_cidr_ipv4 : {
          key  = "${port}::${cidr}"
          port = port
          cidr = cidr
        }
      ]
    ]) : pair.key => pair
  }

  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr

  description = "Allow listener traffic from CIDR ${each.value.cidr} to port ${each.value.port}"
}

############################################
# Ingress rules from source security groups
############################################
#
# This supports SG-to-SG least-privilege patterns, for example:
# - only specific workload/security groups can reach the ALB
# - no broad CIDR needed for internal service traffic
############################################

resource "aws_vpc_security_group_ingress_rule" "from_sg_by_port" {
  for_each = {
    for pair in flatten([
      for port in local.listener_ports : [
        for source_sg_id in var.ingress_source_security_group_ids : {
          key          = "${port}::${source_sg_id}"
          port         = port
          source_sg_id = source_sg_id
        }
      ]
    ]) : pair.key => pair
  }

  security_group_id            = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
  referenced_security_group_id = each.value.source_sg_id

  description = "Allow listener traffic from security group ${each.value.source_sg_id} to port ${each.value.port}"
}

############################################
# Egress rules
############################################
#
# ALB needs outbound connectivity to reach targets
# and perform health checks. We keep this configurable
# via var.egress_cidr_ipv4 and create one rule per CIDR.
############################################

resource "aws_vpc_security_group_egress_rule" "to_cidr" {
  for_each = toset(var.egress_cidr_ipv4)

  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = each.value

  description = "Allow outbound traffic from ALB to ${each.value}"
}
