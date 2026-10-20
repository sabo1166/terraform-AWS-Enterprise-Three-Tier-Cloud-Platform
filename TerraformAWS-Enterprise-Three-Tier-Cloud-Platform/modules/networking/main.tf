data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  # Exactly two AZs, picked dynamically from the region. Keys "a"/"b" are stable
  # for_each keys and index into the CIDR lists.
  azs = {
    a = data.aws_availability_zones.available.names[0]
    b = data.aws_availability_zones.available.names[1]
  }
  az_index = { a = 0, b = 1 }

  # One NAT Gateway in AZ-A ("single") or one per AZ ("per_az").
  nat_keys = !var.enable_nat_gateway ? [] : (var.nat_gateway_mode == "per_az" ? ["a", "b"] : ["a"])
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name}-vpc" })

  lifecycle {
    precondition {
      condition     = length(data.aws_availability_zones.available.names) >= 2
      error_message = "The selected region must offer at least two available Availability Zones."
    }
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = local.azs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = var.public_subnet_cidrs[local.az_index[each.key]]
  map_public_ip_on_launch = false # only the ALB/NAT live here; nothing else needs a public IP

  tags = merge(var.tags, { Name = "${var.name}-public-${each.key}", Tier = "public" })
}

resource "aws_subnet" "private_app" {
  for_each = local.azs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = var.private_app_subnet_cidrs[local.az_index[each.key]]
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "${var.name}-private-app-${each.key}", Tier = "application" })
}

resource "aws_subnet" "private_db" {
  for_each = local.azs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = var.private_db_subnet_cidrs[local.az_index[each.key]]
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "${var.name}-private-db-${each.key}", Tier = "database" })
}

# ---------------------------------------------------------------------------
# NAT Gateway(s) (billable: hourly + data processing)
# ---------------------------------------------------------------------------
resource "aws_eip" "nat" {
  for_each = toset(local.nat_keys)

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat-eip-${each.key}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_keys)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })

  depends_on = [aws_internet_gateway.this]
}

# ---------------------------------------------------------------------------
# Route tables
# ---------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# One route table per AZ so "per_az" NAT mode can route each AZ to its own NAT.
resource "aws_route_table" "private_app" {
  for_each = local.azs

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-private-app-rt-${each.key}" })
}

resource "aws_route" "private_app_nat" {
  for_each = var.enable_nat_gateway ? local.azs : {}

  route_table_id         = aws_route_table.private_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.nat_gateway_mode == "per_az" ? each.key : "a"].id
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.key].id
}

# Database subnets have no route to the internet at all.
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-private-db-rt" })
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}
