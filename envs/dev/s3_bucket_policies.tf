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
      "${module.s3_bucket_logs.bucket_arn}/app/*"
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
