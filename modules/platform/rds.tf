resource "random_password" "db_master_pass" {
  length           = 20
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    pass_version = 1
  }
}

resource "aws_secretsmanager_secret" "db_password_secret" {
  name = "${var.data.environment}_${var.common.project}_db_password_secret"
}

# Use in Production but requires setup of a Lambda
# resource "aws_secretsmanager_secret_rotation" "example" {
#   secret_id           = aws_secretsmanager_secret.db_password_secret.id
#   rotation_lambda_arn = aws_lambda_function.example.arn

#   rotation_rules {
#     automatically_after_days = 30
#   }
# }

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = random_password.db_master_pass.result
  depends_on = [
    aws_secretsmanager_secret.db_password_secret,
    random_password.db_master_pass,
  ]
}

data "aws_secretsmanager_secret_version" "db_password_secret" {
  secret_id = aws_secretsmanager_secret.db_password_secret.id
  depends_on = [
    aws_secretsmanager_secret_version.db_password_secret_version
  ]
}

resource "aws_rds_cluster" "database" {
  lifecycle {
    ignore_changes = [
      availability_zones # added to ensure cluster is not recreated on every run
    ]
  }
  cluster_identifier                  = "${var.data.environment}${var.common.project}"
  engine                              = "aurora-mysql"
  engine_mode                         = "provisioned"
  engine_version                      = "8.0.mysql_aurora.3.02.0"
  database_name                       = "${var.data.environment}${var.data.environment_data.database_name}"
  availability_zones                  = var.data.availability_zones
  master_username                     = var.common.master_username
  master_password                     = data.aws_secretsmanager_secret_version.db_password_secret.secret_string
  backup_retention_period             = 7
  preferred_backup_window             = "03:00-04:00"
  deletion_protection                 = var.data.production == true ? true : false
  skip_final_snapshot                 = var.data.production == false ? true : false
  final_snapshot_identifier           = "${var.data.environment}-${var.common.project}-final-snapshot"
  db_subnet_group_name                = aws_db_subnet_group.database.name
  vpc_security_group_ids              = [aws_security_group.database_rds_sg.id]
  iam_database_authentication_enabled = true
  # Take care when changing password on Production as the password will not update until maintenance window!
  apply_immediately                   = var.data.production == false ? true : false
  storage_encrypted                   = true

  serverlessv2_scaling_configuration {
    max_capacity = 64.0 # Max 128
    min_capacity = 0.5
  }
  depends_on = [
    aws_secretsmanager_secret_version.db_password_secret_version
  ]
}

resource "aws_rds_cluster_instance" "serverless_v2_mysql_instance" {
  cluster_identifier   = "${var.data.environment}${var.common.project}" #Use local value to ensure is not replace on each run
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.database.engine
  engine_version       = aws_rds_cluster.database.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.database.name
  # Take care when changing password on Production as the password will not update until maintenance window!
  apply_immediately    = var.data.production == false ? true : false

  tags = {
    Name = "${var.data.environment}-${var.common.project}-mysql-instance"
  }
  depends_on = [
    aws_rds_cluster.database
  ]
}

resource "aws_security_group" "database_rds_sg" {
  name_prefix = "${var.data.environment}-${var.common.project}-rds-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
}

resource "aws_db_subnet_group" "database" {
  name = "${var.data.environment}-${var.common.project}-rds"
  subnet_ids = data.aws_subnets.private_subnets.ids
  depends_on = [
    data.aws_subnets.private_subnets
  ]
}

resource "aws_rds_cluster_parameter_group" "database" {
  name        = "${var.data.environment}-${var.common.project}-parameter-group"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL 8.0 parameter group"
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
}