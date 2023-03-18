resource "aws_s3_bucket" "bucket" {

  bucket = "${var.common.project}-${var.common.s3_bucket}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Company = "Lepaya"
    Environment = var.data.environment
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "s3:*",
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

resource "aws_s3_bucket_object" "bucket" {
  for_each = fileset(path.module, "data/*.json")
  bucket   = aws_s3_bucket.bucket.id
  key      = each.key
  acl      = "private" # or can be "public-read"
  source   = each.key
  etag     = filemd5("${each.key}")
}
