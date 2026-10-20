variable "name" {
  description = "Name prefix for networking resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDRs of the two public subnets, ordered [AZ-A, AZ-B]."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2 && alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "public_subnet_cidrs must contain exactly two valid CIDR blocks."
  }
}

variable "private_app_subnet_cidrs" {
  description = "CIDRs of the two private application subnets, ordered [AZ-A, AZ-B]."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_app_subnet_cidrs) == 2 && alltrue([for c in var.private_app_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "private_app_subnet_cidrs must contain exactly two valid CIDR blocks."
  }
}

variable "private_db_subnet_cidrs" {
  description = "CIDRs of the two private database subnets, ordered [AZ-A, AZ-B]."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]

  validation {
    condition     = length(var.private_db_subnet_cidrs) == 2 && alltrue([for c in var.private_db_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "private_db_subnet_cidrs must contain exactly two valid CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway(s) so private application instances can reach package repositories. Billable. If false, instances cannot install Nginx."
  type        = bool
  default     = true
}

variable "nat_gateway_mode" {
  description = "\"single\" = one NAT Gateway in AZ-A (cheapest, but AZ-A is a single point of failure for egress); \"per_az\" = one NAT Gateway per AZ (higher availability, roughly double the NAT cost)."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be \"single\" or \"per_az\"."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
