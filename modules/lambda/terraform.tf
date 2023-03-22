locals {
  my_function_source = "../../src/lambda_function.zip"
}

resource "aws_s3_bucket" "builds" {
  bucket = "${var.common.project}-builds-bucket"
  acl    = "private"
}

resource "aws_s3_object" "upload_file" {
  bucket = aws_s3_bucket.builds.id
  key    = "${filemd5(local.my_function_source)}.zip"
  source = local.my_function_source
}

data "aws_caller_identity" "current" {}

module "lambda_function_in_vpc" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "my-lambda-in-vpc"
  description   = "Upload CSV to RDS Lambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  environment_variables = {
    "S3_BUCKET_NAME"          = "${var.S3_BUCKET_NAME}",
    "S3_OBJECT_KEY"           = "${var.S3_OBJECT_KEY}"
    "RDS_HOST"                = "${var.RDS_HOST}"
    "RDS_DATABASE"            = "${var.RDS_DATABASE}"
    "RDS_TABLE"               = "${var.RDS_TABLE}"
    "SECRETS_NAME"            = "${var.SECRETS_NAME}"
    "POWERTOOLS_SERVICE_NAME" = "lambda"
    "LOG_LEVEL"               = "ERROR"
    "REGION"                  = "${var.common.region}"
  }

  source_path    = "../../src"
  create_package = false

  vpc_subnet_ids         = var.private_subnets
  vpc_security_group_ids = [var.vpc.default_security_group_id]
  # attach_network_policy  = true

  s3_existing_package = {
    bucket = aws_s3_bucket.builds.id
    key    = aws_s3_object.upload_file.id
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces"],
      resources = ["*"]
    },
    secrets_manager = {
      effect    = "Allow",
      actions   = ["secretsmanager:*"],
      resources = ["*"]
    },
    s3_read = {
      effect    = "Allow",
      actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      resources = ["${aws_s3_bucket.builds.arn}/*"]
    },
    ec2_delete_network_interface = {
      effect    = "Allow",
      actions   = ["ec2:DeleteNetworkInterface"],
      resources = ["arn:aws:ec2:${var.common.region}:${data.aws_caller_identity.current.id}:*/*"]
    }
  }

  tags = {
    Module = var.common.project
  }
  depends_on = [
    data.aws_caller_identity.current
  ]
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  target_id = module.lambda_function_in_vpc.lambda_function_name
  rule      = aws_cloudwatch_event_rule.trigger_lambda.name
  arn       = module.lambda_function_in_vpc.lambda_function_arn
}

resource "aws_cloudwatch_event_rule" "trigger_lambda" {
  name_prefix         = "lambda_csv"
  schedule_expression = "cron(0 * * * *)"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_in_vpc.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_lambda.arn
}