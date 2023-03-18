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

module "vpc" {
  source   = "../../modules/platform"
  common = var.common
  network_data = var.network_data
  availability_zones = var.availability_zones
  environment = var.environment
}