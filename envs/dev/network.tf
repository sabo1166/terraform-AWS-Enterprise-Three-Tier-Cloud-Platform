# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # needed by RDS endpoints and SSM later

  tags = { Name = "${local.name_prefix}-vpc" }
}

# Take over the default security group and give it no rules, so nothing can
# be attached to it by accident and gain access.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-default-locked" }
}

# ---------------------------------------------------------------------------
# Subnets: public (ALB, NAT), private app (EC2), private db (RDS)
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.name
  cidr_block        = local.public_cidrs[each.key]

  # Nothing launched here needs an auto-assigned public IP: the ALB and NAT
  # gateways get their addresses explicitly.
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "app" {
  for_each = local.az_map

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.name
  cidr_block        = local.app_cidrs[each.key]

  tags = {
    Name = "${local.name_prefix}-app-${each.key}"
    Tier = "app"
  }
}

resource "aws_subnet" "db" {
  for_each = local.az_map

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.name
  cidr_block        = local.db_cidrs[each.key]

  tags = {
    Name = "${local.name_prefix}-db-${each.key}"
    Tier = "db"
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway and public routing
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-igw" }
}

# One shared public route table: both public subnets route identically.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# NAT Gateway(s): outbound-only internet for the app tier. Strategy is set by
# var.nat_mode (see locals.tf). Billable: hourly charge + per-GB processing.
# ---------------------------------------------------------------------------
resource "aws_eip" "nat" {
  for_each = local.nat_azs

  domain = "vpc"

  tags = { Name = "${local.name_prefix}-nat-eip-${each.key}" }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  for_each = local.nat_azs

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = { Name = "${local.name_prefix}-nat-${each.key}" }

  depends_on = [aws_internet_gateway.main]
}

# ---------------------------------------------------------------------------
# App tier routing: one route table per AZ so per_az mode can point each AZ at
# its own NAT. In single mode every table points at the one shared NAT.
# ---------------------------------------------------------------------------
resource "aws_route_table" "app" {
  for_each = local.az_map

  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-app-rt-${each.key}" }
}

resource "aws_route" "app_nat" {
  for_each = local.az_map

  route_table_id         = aws_route_table.app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[var.nat_mode == "single" ? "az1" : each.key].id
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app[each.key].id
}

# ---------------------------------------------------------------------------
# DB tier routing: a single table with ONLY the implicit local route. The
# database subnets have no path to or from the internet.
# ---------------------------------------------------------------------------
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-db-rt" }
}

resource "aws_route_table_association" "db" {
  for_each = aws_subnet.db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.db.id
}

# ---------------------------------------------------------------------------
# S3 gateway endpoint (free): keeps S3 traffic from the app tier off the NAT,
# which saves per-GB NAT processing charges and keeps it on the AWS network.
# ---------------------------------------------------------------------------
data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.app : rt.id]

  tags = { Name = "${local.name_prefix}-s3-endpoint" }
}
