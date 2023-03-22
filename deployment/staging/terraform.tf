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
  source = "../../modules/platform"
  common = var.common
  data   = var.data
}

resource "aws_s3_bucket_object" "csv" {
  bucket   = module.platform.aws_s3_bucket_output.id
  key      = "data/Random_emails.csv"
  acl      = "private" # or can be "public-read"
  source   = "data/Random_emails.csv"
  etag     = filemd5("data/Random_emails.csv")

  depends_on = [
    module.platform
  ]
}