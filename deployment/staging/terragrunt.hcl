locals {
  container_id  = basename(get_terragrunt_dir())
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs
  environment_data = read_terragrunt_config(find_in_parent_folders("environment.hcl")).inputs
}

remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = local.common.terraform_state_s3_bucket_prefix
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
    environment_data = local.environment_data.staging
    availability_zones  = ["${local.common.region}a", "${local.common.region}b"]
    production = false
  }
}