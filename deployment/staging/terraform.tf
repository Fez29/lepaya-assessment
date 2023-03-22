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
  bucket = module.platform.aws_s3_bucket_output.id
  key    = "data/Random_emails.csv"
  acl    = "private" # or can be "public-read"
  source = "data/Random_emails.csv"
  etag   = filemd5("data/Random_emails.csv")

  depends_on = [
    module.platform
  ]
}

module "lambda" {
  source          = "../../modules/lambda"
  common          = var.common
  data            = var.data
  vpc             = module.platform.vpc
  private_subnets = module.platform.private_subnets
  RDS_HOST        = module.platform.RDS_HOST
  RDS_DATABASE    = module.platform.RDS_DATABASE
  SECRETS_NAME    = module.platform.SECRETS_NAME
  S3_OBJECT_KEY   = aws_s3_bucket_object.csv.key
  S3_BUCKET_NAME  = module.platform.aws_s3_bucket_output.id
  #TODO
  RDS_TABLE = "emails"

  depends_on = [
    aws_s3_bucket_object.csv,
    module.platform
  ]
}