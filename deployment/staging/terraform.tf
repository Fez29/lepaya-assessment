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