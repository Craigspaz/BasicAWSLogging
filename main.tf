provider "aws" {
    region = var.region
    assume_role {
      role_arn = var.deployment_role
      session_name = "AFT"
      external_id = length(var.external_id) == 0 ? null : var.external_id
    }
}

locals {
    cloudtrail_name = "maintrail"
}

data "aws_caller_identity" "current" {
    count = var.deploy_resources == true ? 1 : 0
}

data "aws_partition" "current" {
    count = var.deploy_resources == true ? 1 : 0
}

data "aws_region" "current" {
    count = var.deploy_resources == true ? 1 : 0
}

resource "aws_cloudtrail" "main_trail" {
  depends_on = [ aws_s3_bucket_policy.main_trail_s3_policy ]
  count = var.deploy_resources == true ? 1 : 0
  name = local.cloudtrail_name
  s3_bucket_name = aws_s3_bucket.main_trail_s3[count.index].id
  include_global_service_events = true
  enable_log_file_validation = true
  enable_logging = true
  is_multi_region_trail = true
}

resource "aws_s3_bucket" "main_trail_s3" {
    count = var.deploy_resources == true ? 1 : 0
    bucket = "maincloudtrail-${data.aws_caller_identity.current[count.index].account_id}"
    lifecycle {
      prevent_destroy = true
    }
}

data "aws_iam_policy_document" "main_trail_policy" {
    count = var.deploy_resources == true ? 1 : 0
    statement {
      sid    = "AWSCloudTrailAclCheck"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
      actions = ["s3:GetBucketAcl"]
      resources = [aws_s3_bucket.main_trail_s3[count.index].arn]
      condition {
        test = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:${data.aws_partition.current[count.index].partition}:cloudtrail:${data.aws_region.current[count.index].name}:${data.aws_caller_identity.current[count.index].account_id}:trail/${local.cloudtrail_name}"]
      }
    }

    statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.main_trail_s3[count.index].arn}/AWSLogs/${data.aws_caller_identity.current[count.index].account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current[count.index].partition}:cloudtrail:${data.aws_region.current[count.index].name}:${data.aws_caller_identity.current[count.index].account_id}:trail/${local.cloudtrail_name}"]
    }
  }
}

resource "aws_s3_bucket_policy" "main_trail_s3_policy" {
    count = var.deploy_resources == true ? 1 : 0
    bucket = aws_s3_bucket.main_trail_s3[count.index].id
    policy = data.aws_iam_policy_document.main_trail_policy[count.index].json
}