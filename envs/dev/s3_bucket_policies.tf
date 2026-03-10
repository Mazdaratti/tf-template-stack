############################################
# S3 bucket policies (dev)
#
# Purpose:
# Allow S3 Server Access Logging to deliver logs from the app bucket
# into the logs bucket under a dedicated prefix ("app/").
#
# What happens if we do NOT attach this policy?
# - The app bucket may have access logging enabled,
#   but S3 will not be allowed to write objects into the destination bucket.
# - Result: access logs are not delivered (AccessDenied).
############################################

data "aws_iam_policy_document" "s3_access_logs_delivery" {
  statement {
    sid    = "AllowS3ServerAccessLogsDelivery"
    effect = "Allow"

    # S3 server access logs are delivered by this AWS service principal.
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    # Log delivery only needs PutObject into the destination bucket/prefix.
    actions = [
      "s3:PutObject"
    ]

    # Restrict writes to a dedicated prefix to avoid mixing log sources.
    resources = [
      "${local.logs_bucket_arn}/app/*"
    ]

    # Restrict to the same AWS account to reduce blast radius.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
    # Restrict to logs originating from this specific source bucket.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        module.s3_bucket_app.bucket_arn
      ]
    }
  }
}

############################################
# ALB access logs delivery (dev)
#
# Purpose:
# Allow the Application Load Balancer to deliver
# access logs into the shared logs bucket under
# the dedicated "alb/" prefix.
############################################

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
      "${local.logs_bucket_arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    # Restrict log delivery to load balancers
    # in this AWS account and region.
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/*"
      ]
    }
  }
}

############################################
# Combined logs bucket policy (dev)
#
# The shared logs bucket must allow multiple
# writers. For the current dev baseline:
# - S3 server access logs from the app bucket
# - ALB access logs from the ingress layer
############################################

data "aws_iam_policy_document" "logs_bucket_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.s3_access_logs_delivery.json,
    data.aws_iam_policy_document.alb_access_logs_delivery.json
  ]
}
