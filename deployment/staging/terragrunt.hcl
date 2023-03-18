locals {
  container_id  = basename(get_terragrunt_dir())
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs
  network     = {
    vpc_cidr_block = "172.16.0.0/16"
    public_subnet_cidrs = ["172.16.1.0/24", "172.16.2.0/24"]
    private_subnet_cidrs = ["172.16.3.0/24", "172.16.4.0/24"]
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
    production = false
  }
}