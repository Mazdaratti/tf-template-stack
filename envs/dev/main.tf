# Development Environment - Main Configuration

############################################
# Local naming helpers
#
# We keep the logs bucket name/ARN in one place
# so both:
# - module "s3_bucket_logs"
# - env-defined bucket policies
# use the same value.
#
# This avoids:
# - duplicating the naming expression
# - introducing a dependency cycle by referencing
#   module.s3_bucket_logs outputs inside the policy
#   document that is passed back into that module
############################################
locals {
  logs_bucket_name = "${var.project_name}-${var.environment}-logs-${data.aws_caller_identity.current.account_id}"
  logs_bucket_arn  = "arn:aws:s3:::${local.logs_bucket_name}"
}

###################################
# MODULE - NETWORK
###################################

module "network" {
  source = "../../modules/network"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # VPC
  vpc_cidr             = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  # AZ Selection
  azs      = var.azs
  az_count = var.az_count

  # Subnet toggles
  create_public_subnets  = var.create_public_subnets
  create_private_subnets = var.create_private_subnets

  # Hybrid subnet sizing
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # Public subnet behavior
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

###################################
# MODULE - NAT GATEWAY 
###################################

module "nat_gateway" {
  source = "../../modules/nat_gateway"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Wiring from network module outputs (AZ-name keyed)
  public_subnet_ids_by_az       = module.network.public_subnet_ids_by_az
  private_route_table_ids_by_az = module.network.private_route_table_ids_by_az

  # Defaults for dev (can be overridden via variables.tf)
  enabled       = var.enable_nat_gateway
  mode          = var.nat_gateway_mode
  create_routes = var.nat_create_routes

  # Optional: reuse existing EIPs (leave null to create new EIPs)
  reuse_eip_allocation_ids = var.nat_reuse_eip_allocation_ids
}

###################################
# MODULE - VPC GATEWAY ENDPOINTS (S3, DynamoDB)
###################################

module "vpc_gateway_endpoints" {
  source = "../../modules/vpc_gateway_endpoints"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Wiring from network module outputs
  vpc_id = module.network.vpc_id
  # Recommended: attach gateway endpoints to private route tables
  route_table_ids = values(module.network.private_route_table_ids_by_az)

  # Enable both endpoints by default in dev for testing/demo purposes
  gateway_endpoints = {
    s3       = true
    dynamodb = true
  }

  # Endpoint policies (optional):
  # If omitted for a service, AWS default endpoint policy is used.
  #
  # Here we restrict S3 access through the gateway endpoint to ONLY the
  # environment buckets (logs + app). This prevents access to other buckets
  # via this endpoint while keeping S3 functionality intact.
  endpoint_policy_json = {
    s3 = data.aws_iam_policy_document.vpce_s3_restricted_to_env_buckets.json
  }

}

############################################
# VPC Interface Endpoints (PrivateLink)
############################################

module "vpc_interface_endpoints" {
  source = "../../modules/vpc_interface_endpoints"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Wiring from network module outputs
  vpc_id = module.network.vpc_id
  # Recommended: attach gateway endpoints to private route tables
  subnet_ids = module.network.private_subnet_ids

  # Simple default for this template: module-managed SG
  create_security_group = true

  # Real-world platform pattern: external/shared SG (recommended later)
  # - create_security_group = false
  # - security_group_ids    = [aws_security_group.vpce_shared.id]
  #
  # Example SG + rule templates live in:
  # - envs/dev/security_groups.tf.example


  # Keep only the endpoint that is exercised by the current dev stack.
  #
  # The ECS service writes container logs to CloudWatch Logs from private
  # subnets, so `logs` is the only interface endpoint with a clear runtime
  # use in this baseline.
  #
  # We intentionally do not enable the SSM trio or Secrets Manager here:
  # - ECS Exec is disabled
  # - no EC2/SSM-managed instance exists in the VPC
  # - the current workload does not read from Secrets Manager
  interface_endpoints = {
    logs = { enabled = true }
  }

  # Optional: endpoint policies
  #
  # - Examples live in envs/dev/endpoint_policies.tf.example
  # - Active policies should be defined in envs/dev/endpoint_policies.tf
  #
  # If a service is omitted, AWS default endpoint policy is used.
  #
  # endpoint_policy_json = {
  #   secretsmanager = data.aws_iam_policy_document.vpce_secretsmanager_restricted.json
  #   logs           = data.aws_iam_policy_document.vpce_logs_restricted.json
  # }

}

###################################
# MODULE - KMS KEYS
###################################

module "kms_keys" {
  source = "../../modules/kms_keys"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Optional:
  # alias_prefix = "${var.project_name}-${var.environment}"

  #***********************************
  # Foundation baseline keys (dev)
  #***********************************

  # Keep only the keys that are exercised by the current dev baseline:
  # - logs: for logging_baseline / vpc_flow_logs / ECS service logs
  # - s3: for secure S3 bucket encryption
  #
  # Dev teardown preference:
  # - use the minimum allowed KMS deletion window (7 days)
  # - this reduces cleanup friction after validation
  # - production environments typically use longer windows such as 30 days
  #   to preserve a stronger recovery buffer before permanent deletion


  keys = {
    logs = {
      description             = "KMS key for log encryption"
      deletion_window_in_days = 7
      policy                  = data.aws_iam_policy_document.logs_kms.json
    }

    s3 = {
      description             = "KMS key for S3 bucket encryption"
      deletion_window_in_days = 7
    }
  }

  # Optional: custom key policies
  # - Examples live in envs/dev/kms_key_policies.tf.example
  # - Active policies should be defined in envs/dev/kms_key_policies.tf
  #
  # Then pass per key as: policy = data.aws_iam_policy_document.<name>.json

}

###################################
# MODULE - S3 BUCKETS (LOGS + APP)
#
# We create two buckets using the same reusable s3_bucket module:
#
# - s3_bucket_logs:
#   Central destination bucket for S3 server access logs and ALB access logs.
#   Uses SSE-S3 encryption because both delivery paths require an SSE-S3
#   destination bucket.
#
# - s3_bucket_app:
#   Example application bucket.
#   Uses the dedicated KMS key: key_arns["s3"].
#   Sends its server access logs to s3_bucket_logs under prefix "app/".
#
# Why this split?
# - The app bucket still uses its own dedicated KMS key for application data
# - The shared logs bucket stays on SSE-S3 because AWS log delivery requires it
# - CloudWatch Logs still use the dedicated "logs" KMS key elsewhere in this env
#
# Naming:
# S3 bucket names must be globally unique. We append the AWS account ID to
# make names deterministic and unique per AWS account.
###################################

module "s3_bucket_logs" {
  source = "../../modules/s3_bucket"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  bucket_name = local.logs_bucket_name

  # If false (default in module), Terraform will refuse to destroy a non-empty bucket.
  # In dev we set true for convenience; in stage/prod you typically keep this false.
  force_destroy = true

  # Encryption:
  # - the shared logs bucket receives ALB access logs and S3 server access logs
  # - both delivery paths require the destination bucket to use SSE-S3
  # - we therefore keep this bucket on S3-managed encryption
  # - the dedicated "logs" KMS key is still used for CloudWatch Logs, not for
  #   this S3 destination bucket
  encryption = {
    type = "S3"
  }

  # Versioning:
  # - In dev we keep this disabled to reduce destroy friction for short-lived
  #   validation environments.
  # - Production-style environments often keep versioning enabled for stronger
  #   recovery guarantees and longer-lived data retention.
  versioning_enabled = false

  # Bucket policy (optional):
  # If omitted (module default), no additional bucket policy is attached
  # beyond the module’s baseline TLS-only deny policy.
  # Here we attach the env-defined combined policy that allows:
  # - S3 server access log delivery from the app bucket
  # - ALB access log delivery from the dev ingress layer
  policy_json = data.aws_iam_policy_document.logs_bucket_combined.json

  # Lifecycle rules (optional):
  # If omitted (default), S3 will not expire objects automatically.
  # Logs buckets usually have lifecycle rules to control cost.
  lifecycle_rules = [
    {
      id              = "expire-logs"
      enabled         = true
      expiration_days = 90
    },
    {
      id                                 = "expire-noncurrent"
      enabled                            = true
      noncurrent_version_expiration_days = 30
    },
    {
      id                                     = "abort-multipart"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
    }
  ]
}

module "s3_bucket_app" {
  source = "../../modules/s3_bucket"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  bucket_name = "${var.project_name}-${var.environment}-app-${data.aws_caller_identity.current.account_id}"

  # If false (default in module), Terraform will refuse to destroy a non-empty bucket.
  # In dev we set true for convenience; in stage/prod you typically keep this false.
  force_destroy = true

  # Encryption:
  # - type = "KMS" enables SSE-KMS.
  # - kms_key_arn selects the customer-managed KMS key created by kms_keys.
  encryption = {
    type        = "KMS"
    kms_key_arn = module.kms_keys.key_arns["s3"]
  }

  # Versioning:
  # - In dev we keep this disabled to reduce destroy friction for short-lived
  #   validation environments.
  # - Production-style environments often keep versioning enabled for stronger
  #   recovery guarantees and longer-lived data retention.
  versioning_enabled = false

  # Server access logging (optional):
  # If access_logging.enabled = false (module default), no logs are delivered.
  # When enabled, S3 writes access logs for this bucket into the target bucket/prefix.
  access_logging = {
    enabled       = true
    target_bucket = module.s3_bucket_logs.bucket_name
    target_prefix = "app/"
  }
}

###################################
# MODULE - LOGGING BASELINE
#
# Shared CloudWatch Log Groups used as platform primitives.
#
# For now we create only one log group:
# - vpc_flow_logs: destination for the upcoming vpc_flow_logs module.
#
# Retention:
# - dev: 30 days (keep low for cost)
# - prod: consider 90+ days
#
# Encryption:
# - uses the dedicated "logs" KMS key created by kms_keys module
###################################

module "logging_baseline" {
  source = "../../modules/logging_baseline"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Naming:
  # /<project>/<environment>/<suffix>
  log_group_name_prefix = "/${var.project_name}/${var.environment}"

  # Default retention (dev baseline)
  retention_in_days = 30

  # Encrypt CloudWatch Logs using the dedicated logs KMS key
  kms_key_arn = module.kms_keys.keys["logs"].key_arn

  log_groups = {
    vpc_flow_logs = {
      name_suffix = "vpc-flow-logs"
    }
  }
}

############################################
# MODULE - VPC FLOW LOGS
#
# Enables VPC Flow Logs and publishes to the shared CloudWatch Log Group
# created by logging_baseline.
############################################

module "vpc_flow_logs" {
  source = "../../modules/vpc_flow_logs"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Wiring
  vpc_id        = module.network.vpc_id
  log_group_arn = module.logging_baseline.log_group_arns["vpc_flow_logs"]

  # Optional arguments (defaults shown)
  #
  # traffic_type             = "ALL"
  # max_aggregation_interval = 600
  # permissions_boundary_arn = null
}

############################################
# Module: route53_private_zones
############################################
#
# Baseline private DNS namespace for the dev VPC.
#
# - Creates a private hosted zone
# - Associates it with the dev VPC
# - Records are optional (keep commented unless needed)
############################################

module "route53_private_zones" {
  source = "../../modules/route53_private_zones"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  zones = {
    internal = {
      domain_name   = "${var.environment}.internal"
      force_destroy = true

      vpc_associations = [
        {
          vpc_id = module.network.vpc_id
        }
      ]

      # Optional baseline records (examples)
      #
      # records = {
      #   "@" = {
      #     type   = "TXT"
      #     ttl    = 300
      #     values = ["dev private zone"]
      #   }
      #
      #   api = {
      #     type   = "CNAME"
      #     ttl    = 300
      #     values = ["internal-api.example.local"]
      #   }
      # }
    }
  }
}

############################################
# MODULE - ECS CLUSTER
#
# Baseline ECS cluster for dev compute foundation.
# Scope intentionally limited to cluster-level primitives:
# - no services
# - no task definitions
# - no load balancing
############################################

module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Optional naming override (module default applies when null)
  cluster_name = var.ecs_cluster_name

  # Dev baseline observability
  enable_container_insights = var.ecs_enable_container_insights

  # Keep ECS Exec disabled in dev baseline for now.
  exec_enabled = false
}

############################################
# MODULE - ALB INGRESS
#
# Shared ingress baseline for future ECS service modules.
# Scope in dev:
# - one internal ALB in private subnets
# - one HTTP listener (:80)
# - one IP target group for later ECS attachment
# - ALB access logs enabled to the shared logs bucket
############################################

module "alb_ingress" {
  source = "../../modules/alb_ingress"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Core wiring
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  # Dev baseline: internal-only ingress
  internal = true

  # Allow callers from within the VPC CIDR.
  ingress_cidr_ipv4 = [var.vpc_cidr]
  egress_cidr_ipv4  = ["0.0.0.0/0"]

  # Baseline target group for future ECS service attachment
  target_groups = {
    app = {
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"

      health_check = {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200-399"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }

  # Baseline HTTP listener
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "app"
      }
    }
  }

  # Enable ALB access logs in dev and write them
  # into the shared logs bucket under a dedicated prefix.
  access_logs = {
    enabled = true
    bucket  = module.s3_bucket_logs.bucket_name
    prefix  = "alb"
  }
}

############################################
# MODULE - ECS FARGATE SERVICE
#
# First workload-layer baseline in dev.
#
# Design choices in this env wiring:
# - service runs in private subnets
# - tasks do not receive public IPs
# - ingress is allowed only from the ALB security group
# - service attaches to the shared "app" target group from alb_ingress
# - service log group is encrypted with the shared logs KMS key
#
# Why keep this opinionated in envs/dev?
# - dev should stay small and predictable
# - this avoids exposing every module input at the root layer
# - it demonstrates the intended platform -> ingress -> service composition
############################################

module "ecs_fargate_service" {
  source = "../../modules/ecs_fargate_service"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  ##########################################
  # Core wiring
  ##########################################
  cluster_arn = module.ecs_cluster.cluster_arn
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.private_subnet_ids

  ##########################################
  # Service baseline
  ##########################################
  desired_count    = 1
  assign_public_ip = false

  cpu    = 256
  memory = 512

  # The shared dev target group health check uses "/",
  # so the container must answer successfully on that path.
  container = {
    name  = "app"
    image = var.ecs_service_image_uri
    port  = 8080
    command = [
      "sh",
      "-c",
      "sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
    ]
  }

  ##########################################
  # Logging
  ##########################################
  enable_cloudwatch_logging = true
  log_retention_in_days     = 30
  log_kms_key_arn           = module.kms_keys.key_arns["logs"]

  ##########################################
  # ALB integration
  ##########################################
  load_balancer = {
    target_group_arn = module.alb_ingress.target_group_arns["app"]
  }

  # Only the shared ALB may reach the service.
  ingress_source_security_group_ids = [module.alb_ingress.security_group_id]

  # Give the service a short warm-up window before ALB
  # health checks affect task replacement decisions.
  health_check_grace_period_seconds = 30
}
