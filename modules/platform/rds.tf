resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_password_secret" {
  name = "${var.data.environment}-${var.common.project}-db_password_secret"
}

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = random_password.db_password.result
}

data "aws_secretsmanager_secret_version" "db_password_secret" {
  secret_id = aws_secretsmanager_secret.db_password_secret.id
  depends_on = [
    aws_secretsmanager_secret.db_password_secret
  ]
}

resource "aws_rds_cluster" "database" {
  # TODO: investigate why availability zones always has c zone
  lifecycle {
    ignore_changes = [
      availability_zones # added to ensure cluster is not recreated on every run
    ]
  }
  cluster_identifier = "${var.data.environment}${var.common.project}"
  engine             = "aurora-mysql"
  engine_mode        = "provisioned"
  engine_version     = "8.0.mysql_aurora.3.02.0"
  database_name      = "${var.data.environment}${var.common.database_name}"
  availability_zones = var.data.availability_zones
  # TODO: change to using AWS secrets
  master_username = var.common.master_username
  #master_password = "password"
  master_password           = data.aws_secretsmanager_secret_version.db_password_secret.secret_string
  backup_retention_period   = 7
  preferred_backup_window   = "03:00-04:00"
  deletion_protection       = var.data.production == true ? true : false
  skip_final_snapshot       = var.data.production == true ? true : false
  final_snapshot_identifier = "${var.data.environment}-${var.common.project}-final-snapshot"
  db_subnet_group_name      = aws_db_subnet_group.database.name
  vpc_security_group_ids    = [aws_security_group.database_rds_sg.id]

  serverlessv2_scaling_configuration {
    max_capacity = 64.0 # Max 128
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "serverless_v2_mysql_instance" {
  count                = 1
  cluster_identifier   = "${var.data.environment}${var.common.project}" #Use local value to ensure is not replace on each run
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.database.engine
  engine_version       = aws_rds_cluster.database.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.database.name

  tags = {
    Name = "${var.data.environment}-${var.common.project}-mysql-instance"
  }
}

resource "aws_security_group" "database_rds_sg" {
  name_prefix = "${var.data.environment}-${var.common.project}-rds-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # TODO: FIXME
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "database" {
  name       = "${var.data.environment}-${var.common.project}-rds"
  subnet_ids = data.aws_subnets.private_subnets.ids # Replace with your preferred subnets
  depends_on = [
    data.aws_subnets.private_subnets
  ]
}

resource "aws_rds_cluster_parameter_group" "database" {
  name        = "${var.data.environment}-${var.common.project}-parameter-group"
  family      = "aurora-mysql5.7"
  description = "Aurora MySQL 5.7 parameter group"
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
}