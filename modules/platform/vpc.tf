# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.data.network_data.vpc_cidr_block
  tags = {
    Name = var.common.project
  }
}

data "aws_vpc" "current" {
  id = aws_vpc.main.id

  depends_on = [
    aws_vpc.main
  ]
}

# Create public subnets
resource "aws_subnet" "public" {
  count             = length(var.data.network_data.public_subnet_cidrs)
  cidr_block        = var.data.network_data.public_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = var.data.availability_zones[count.index]
  tags = {
    Name = "${var.common.project}-public-${count.index}"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.data.network_data.private_subnet_cidrs)
  cidr_block        = var.data.network_data.private_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = var.data.availability_zones[count.index]
  tags = {
    Name = "${var.common.project}-${var.data.environment}-private-${count.index}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.project}-${var.data.environment}-igw"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "${var.common.project}-${var.data.environment}-nat-${count.index}"
  }
}

# Create Elastic IPs for NAT Gateway
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)
  vpc   = true
}

# Create Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.common.project}-${var.data.environment}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.project}-${var.data.environment}-private-rt"
  }
}

# Associate Route Tables with Subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}