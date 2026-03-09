############################################
# Example: with_access_logs
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - Internal ALB baseline
# - HTTP listener on port 80
# - One IP target group for future ECS service attachment
# - ALB access logging enabled to an S3 bucket
# - Bucket policy using current ALB log delivery principal
############################################

provider "aws" {
  # Keep region explicit so example behavior is predictable.
  region = "eu-central-1"
}

############################################
# Minimal network for ALB placement
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.52.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "alb-ingress-logs-example-vpc"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.52.10.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "alb-ingress-logs-example-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.52.11.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "alb-ingress-logs-example-private-b"
  }
}

############################################
# Access logs destination bucket
############################################

resource "aws_s3_bucket" "alb_logs" {
  bucket_prefix = "alb-ingress-access-logs-"

  tags = {
    Name = "alb-ingress-access-logs"
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "alb_access_logs_delivery" {
  statement {
    sid    = "AllowALBAccessLogsDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.alb_logs.arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    # Recommended hardening: only allow log delivery from
    # load balancers in this account and region.
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:elasticloadbalancing:eu-central-1:${data.aws_caller_identity.current.account_id}:loadbalancer/*"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_access_logs_delivery.json
}

module "alb_ingress" {
  source = "../../"

  ##########################################
  # Identity + tags
  ##########################################
  project_name = "alb-ingress-example"
  environment  = "dev"

  common_tags = {
    Owner = "example"
  }

  ##########################################
  # Core wiring
  ##########################################
  vpc_id     = aws_vpc.this.id
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # Internal ALB baseline
  internal = true

  ##########################################
  # Security group ingress/egress
  ##########################################
  ingress_cidr_ipv4 = ["10.52.0.0/16"]
  egress_cidr_ipv4  = ["0.0.0.0/0"]

  ##########################################
  # Listener and target group baseline
  ##########################################
  target_groups = {
    app = {
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
    }
  }

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

  ##########################################
  # Access logs enabled
  ##########################################
  access_logs = {
    enabled = true
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb"
  }
}
