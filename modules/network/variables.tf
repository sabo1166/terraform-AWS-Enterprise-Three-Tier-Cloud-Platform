variable "name_prefix" {
  description = "Prefix for resource names, e.g. three-tier-dev."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must be between /16 and /18 so each /24-/26 subnet carved from it is large enough for an ALB."
  type        = string

  validation {
    condition = (
      can(cidrhost(var.vpc_cidr, 0)) &&
      tonumber(split("/", var.vpc_cidr)[1]) >= 16 &&
      tonumber(split("/", var.vpc_cidr)[1]) <= 18
    )
    error_message = "vpc_cidr must be a valid CIDR with a prefix length between /16 and /18."
  }
}

variable "nat_mode" {
  description = "NAT Gateway strategy: single (one shared, cheaper) or per_az (one per AZ, resilient)."
  type        = string

  validation {
    condition     = contains(["single", "per_az"], var.nat_mode)
    error_message = "nat_mode must be single or per_az."
  }
}
