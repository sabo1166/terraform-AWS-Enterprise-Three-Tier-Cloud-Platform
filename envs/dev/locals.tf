data "aws_availability_zones" "available" {
  state = "available"

  # Skip Local Zones / Wavelength Zones; subnets here are regular-AZ only.
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}"

  # Exactly two AZs, per the architecture. Keys (az1, az2) are stable even if
  # AWS reorders AZ names, so for_each addresses never shift.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  az_map = {
    for i, az in local.azs : "az${i + 1}" => {
      name  = az
      index = i
    }
  }

  # Subnet CIDRs are carved from the VPC CIDR (+8 bits) with fixed index bands
  # per tier, so tiers never overlap and there is room to grow inside each band.
  #   public: 0-1   app: 10-11   db: 20-21
  subnet_newbits = 8
  public_cidrs   = { for k, v in local.az_map : k => cidrsubnet(var.vpc_cidr, local.subnet_newbits, v.index) }
  app_cidrs      = { for k, v in local.az_map : k => cidrsubnet(var.vpc_cidr, local.subnet_newbits, 10 + v.index) }
  db_cidrs       = { for k, v in local.az_map : k => cidrsubnet(var.vpc_cidr, local.subnet_newbits, 20 + v.index) }

  # single  -> one NAT in the first AZ shared by every app subnet (cheaper,
  #            but an outage of that AZ removes outbound access for both AZs).
  # per_az  -> one NAT per AZ, each app subnet uses the NAT in its own AZ.
  nat_azs = var.nat_mode == "single" ? { az1 = local.az_map["az1"] } : local.az_map
}
