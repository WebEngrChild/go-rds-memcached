# ------------------------------------------------------------#
# local variables
# ------------------------------------------------------------#
locals {
  zones         = ["1a", "1c", "1d"]
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_cidrs = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

# ------------------------------------------------------------#
# VPC
# ------------------------------------------------------------#
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = format("%s-%s-aws_vpc", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# Subnet Public
# ------------------------------------------------------------#
resource "aws_subnet" "public" {
  for_each = toset(local.zones)

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-${each.value}"
  cidr_block        = local.public_cidrs[index(local.zones, each.value)]

  tags = {
    Name = format("%s-%s-public-%s", var.environment, var.project, each.value)
  }
}

# ------------------------------------------------------------#
# Subnets Private
# ------------------------------------------------------------#
resource "aws_subnet" "private" {
  for_each = toset(local.zones)

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-${each.value}"
  cidr_block        = local.private_cidrs[index(local.zones, each.value)]

  tags = {
    Name = format("%s-%s-private-%s", var.environment, var.project, each.value)
  }
}

# ------------------------------------------------------------#
# Internet Gateway
# ------------------------------------------------------------#
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-%s-aws_internet_gateway", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# Elastic IP
# ------------------------------------------------------------#
resource "aws_eip" "nat" {
  for_each = toset(local.zones)

  domain = "vpc"

  tags = {
    Name = format("%s-%s-aws_eip-nat_%s", var.environment, var.project, each.value)
  }
}

# ------------------------------------------------------------#
# NAT Gateway
# ------------------------------------------------------------#
resource "aws_nat_gateway" "nat" {
  for_each = toset(local.zones)

  subnet_id     = aws_subnet.public[each.value].id
  allocation_id = aws_eip.nat[each.value].id

  tags = {
    Name = format("%s-%s-nat_%s", var.environment, var.project, each.value)
  }
}

# ------------------------------------------------------------#
# Route Table Public
# ------------------------------------------------------------#
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-%s-aws_route_table-public", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# Route Public
# ------------------------------------------------------------#
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# ------------------------------------------------------------#
# Association Public
# ------------------------------------------------------------#
resource "aws_route_table_association" "public" {
  for_each = toset(local.zones)

  subnet_id      = aws_subnet.public[each.value].id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------#
# Route Table Private
# ------------------------------------------------------------#
resource "aws_route_table" "private" {
  for_each = toset(local.zones)

  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-%s-private_%s", var.environment, var.project, each.value)
  }
}

# ------------------------------------------------------------#
# Route Private
# ------------------------------------------------------------#
resource "aws_route" "private" {
  for_each = toset(local.zones)

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private[each.value].id
  nat_gateway_id         = aws_nat_gateway.nat[each.value].id
}

# ------------------------------------------------------------#
# Association Private
# ------------------------------------------------------------#
resource "aws_route_table_association" "private" {
  for_each = toset(local.zones)

  subnet_id      = aws_subnet.private[each.value].id
  route_table_id = aws_route_table.private[each.value].id
}

# ------------------------------------------------------------#
# SecurityGroup ALB
# ------------------------------------------------------------#
resource "aws_security_group" "alb" {
  name        = var.project
  description = var.project
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = format("%s-%s-aws_security_group-alb", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# SecurityGroup Rule
# ------------------------------------------------------------#
resource "aws_security_group_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress" {
  security_group_id = aws_security_group.alb.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}