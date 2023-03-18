variable "common" {
  type = object({
    terraform_state_s3_bucket = string
    region                    = string
    s3_bucket                 = string
    domain_name               = string
    dynamodb_state_lock       = string
    project                   = string
    database_name             = string
    master_username           = string
  })
}

variable "data" {
  type = object({
    environment = string
    availability_zones = list(string)
    network_data = object({
      vpc_cidr_block = string
      public_subnet_cidrs = list(string)
      private_subnet_cidrs = list(string)
    })
    production = string
  })
}