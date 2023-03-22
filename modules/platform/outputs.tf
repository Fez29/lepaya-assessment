output "vpc" {
  value = aws_vpc.main
}

output "private_subnets" {
  value = data.aws_subnets.private_subnets.ids
}