############################################
# Locals
############################################

locals {
  ##########################################
  # 1. Enforced tags
  ##########################################
  #
  # These tags are mandatory for all resources in this repository.
  #
  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ##########################################
  # 2. Merged tags
  ##########################################
  #
  # Merge user-provided common_tags with enforced tags.
  # Enforced tags are placed last so they cannot be overridden.
  #
  merged_tags = merge(
    var.common_tags,
    local.enforced_tags
  )

  ##########################################
  # 3. Effective service naming
  ##########################################
  #
  # Keep resource names consistent across ECS,
  # IAM, security groups, and CloudWatch logs.
  #
  service_name = coalesce(
    var.name,
    "${var.project_name}-${var.environment}-ecs-service"
  )

  container_name = coalesce(
    try(var.container.name, null),
    local.service_name
  )

  log_group_name = coalesce(
    var.log_group_name,
    "/${var.project_name}/${var.environment}/ecs/${local.service_name}"
  )

  ##########################################
  # 4. Runtime defaults
  ##########################################
  #
  # v1 keeps runtime platform intentionally simple:
  # Linux + x86_64 by default.
  #
  runtime_platform = merge(
    {
      operating_system_family = "LINUX"
      cpu_architecture        = "X86_64"
    },
    var.runtime_platform == null ? {} : var.runtime_platform
  )

  ##########################################
  # 5. Load balancer attachment state
  ##########################################
  #
  # v1 supports one optional target group attachment
  # for the single primary container.
  #
  load_balancer_enabled = var.load_balancer != null

  load_balancer_container_port = (
    var.load_balancer != null && try(var.load_balancer.container_port, null) != null
    ? var.load_balancer.container_port
    : var.container.port
  )

  ##########################################
  # 6. Container definition model
  ##########################################
  #
  # Build a typed container definition locally so:
  # - module inputs stay beginner-friendly
  # - task definition JSON stays stable
  # - optional sections are added only when needed
  #
  container_definition = merge(
    {
      name                   = local.container_name
      image                  = var.container.image
      essential              = try(var.container.essential, true)
      readonlyRootFilesystem = try(var.container.readonly_root_filesystem, false)

      portMappings = [
        {
          containerPort = var.container.port
          hostPort      = var.container.port
          protocol      = "tcp"
        }
      ]
    },
    try(var.container.command, null) != null ? {
      command = var.container.command
    } : {},
    try(var.container.entrypoint, null) != null ? {
      entryPoint = var.container.entrypoint
    } : {},
    length(try(var.container.environment, {})) > 0 ? {
      environment = [
        for key in sort(keys(var.container.environment)) : {
          name  = key
          value = var.container.environment[key]
        }
      ]
    } : {},
    length(try(var.container.secrets, [])) > 0 ? {
      secrets = [
        for secret in var.container.secrets : {
          name      = secret.name
          valueFrom = secret.value_from
        }
      ]
    } : {},
    var.enable_cloudwatch_logging ? {
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.log_group_name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = var.log_stream_prefix
        }
      }
    } : {},
    try(var.container.health_check, null) != null ? {
      healthCheck = merge(
        {
          command = var.container.health_check.command
        },
        try(var.container.health_check.interval, null) != null ? {
          interval = var.container.health_check.interval
        } : {},
        try(var.container.health_check.timeout, null) != null ? {
          timeout = var.container.health_check.timeout
        } : {},
        try(var.container.health_check.retries, null) != null ? {
          retries = var.container.health_check.retries
        } : {},
        try(var.container.health_check.start_period, null) != null ? {
          startPeriod = var.container.health_check.start_period
        } : {}
      )
    } : {}
  )
}
