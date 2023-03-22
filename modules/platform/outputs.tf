output "vpc" {
  value = aws_vpc.main
}

output "private_subnets" {
  value = data.aws_subnets.private_subnets.ids
}

output "RDS_HOST" {
  value = aws_rds_cluster_instance.serverless_v2_mysql_instance.endpoint
}

output "RDS_DATABASE" {
  value = aws_rds_cluster.database.database_name
}

output "SECRETS_NAME" {
  value = data.aws_secretsmanager_secret_version.db_password_secret.arn
}

output "aws_s3_bucket_output" {
  value = aws_s3_bucket.bucket
}