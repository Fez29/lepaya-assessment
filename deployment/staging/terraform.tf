terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

terraform {
  backend "s3" {}
}

module "platform" {
  source   = "../../modules/platform"
  common = var.common
  data = var.data
}

resource "aws_s3_bucket_object" "bucket" {
  for_each = fileset(path.module, "data/*.csv")
  bucket   = module.platform.aws_s3_bucket_output.id
  key      = each.key
  acl      = "private" # or can be "public-read"
  source   = each.key
  etag     = filemd5("${each.key}")
}