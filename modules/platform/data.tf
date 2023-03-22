data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }

  depends_on = [
    aws_subnet.private
  ]
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }

  depends_on = [
    aws_subnet.public
  ]
}

data "aws_vpc" "main" {
  id = aws_vpc.main.id
}
