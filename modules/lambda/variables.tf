variable "common" {
  type = object({
    region                           = string
    domain_name                      = string
    project                          = string
    master_username                  = string
    terraform_state_s3_bucket_prefix = string
  })
}

variable "data" {
  type = object({
    environment        = string
    availability_zones = list(string)
    environment_data = object({
      data_s3_bucket       = string
      dynamodb_state_lock  = string
      database_name        = string
      create_rds_password  = string
      vpc_cidr_block       = string
      public_subnet_cidrs  = list(string)
      private_subnet_cidrs = list(string)
      intra_subnets        = list(string)
    })
    production = string
  })
}

variable "vpc" {}
variable "private_subnets" {}
variable "RDS_HOST" {}
variable "RDS_DATABASE" {}
variable "SECRETS_NAME" {}
variable "RDS_TABLE" {}
variable "S3_OBJECT_KEY" {}
variable "S3_BUCKET_NAME" {}
