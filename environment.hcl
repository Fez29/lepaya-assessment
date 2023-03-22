inputs = {
    staging = {
        data_s3_bucket              = "demo-data-staging"
        dynamodb_state_lock         = "my-lepaya-demo-terraform-state-lock-staging"
        database_name               = "mysqlserverlessv2staging"
        # Only true on first run when creating environment or if you want to change the RDS master user password
        create_rds_password         = true 
        vpc_cidr_block = "172.16.0.0/16"
        public_subnet_cidrs = ["172.16.1.0/24", "172.16.2.0/24"]
        private_subnet_cidrs = ["172.16.3.0/24", "172.16.4.0/24"]
        intra_subnets = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
    }
    production = {
        data_s3_bucket              = "demo-data-production"
        dynamodb_state_lock         = "my-lepaya-demo-terraform-state-lock-production"
        database_name               = "mysqlserverlessv2production"
        # Only true on first run when creating environment or if you want to change the RDS master user password
        create_rds_password         = true 
        vpc_cidr_block = "10.0.0.0/8"
        public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
        private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
        intra_subnets = ["10.10.111.0/24", "10.10.112.0/24", "10.10.113.0/24"]
    }
}
