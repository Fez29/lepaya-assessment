resource "aws_s3_bucket" "bucket" {

  bucket = "${var.common.project}-${var.common.terraform_state_s3_bucket_prefix}-${var.data.environment}"

  versioning {
    enabled = true
  }
  # No longer required as all s3 buckets are now encrypted by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Company     = "Lepaya"
    Environment = var.data.environment
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
  depends_on = [
    aws_s3_bucket.bucket,
    data.aws_iam_policy_document.s3_bucket_policy,
  ]
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${aws_s3_bucket.bucket.arn}"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = ["${aws_vpc.main.id}"]
    }
  }
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = ["${aws_vpc.main.id}"]
    }
  }
}
