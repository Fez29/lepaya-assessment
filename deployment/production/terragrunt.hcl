locals {
  container_id  = path_relative_to_include()
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs
  network  = {
      vpc_cidr_block = "10.0.0.0/8"
      public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
      private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  }
}

remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = local.common.terraform_state_s3_bucket
    key            = "states/${local.container_id}/terraform.tfstate"
    region         = local.common.region
    dynamodb_table = "terraform-locks"
    acl            = "bucket-owner-full-control"

    skip_bucket_enforced_tls = true

    dynamodb_table_tags = {
      Name = "terraform-locks"
    }
  }
}

inputs = {
  common = local.common
  data = {
    environment = local.container_id
    network_data = local.network
    availability_zones  = ["${local.common.region}a", "${local.common.region}b"]
    production = true
  }
}