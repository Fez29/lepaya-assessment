variable "environment" {
}

variable "network_data" {
  type = object({
    vpc_cidr_block = string
    public_subnet_cidrs = list(string)
    private_subnet_cidrs = list(string)
  })
}

variable "common" {
  type = object({
    terraform_state_s3_bucket = string
    region                    = string
    s3_bucket                 = string
    domain_name               = string
    dynamodb_state_lock       = string
    project                   = string
  })
}

variable "availability_zones" {
  type = list(string)
}