variable "name_prefix" {
  description = "Prefix for resource names, e.g. three-tier-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the security groups belong to."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on port 80. The default is open to the internet; restrict it (e.g. to your own IP/32) while testing."
  type        = list(string)

  validation {
    condition     = length(var.alb_ingress_cidrs) > 0 && alltrue([for c in var.alb_ingress_cidrs : can(cidrhost(c, 0))])
    error_message = "alb_ingress_cidrs must be a non-empty list of valid CIDR blocks."
  }
}

variable "app_port" {
  description = "TCP port the application listens on; allowed from the ALB to the app tier."
  type        = number

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "db_port" {
  description = "TCP port of the database (MySQL default 3306); allowed from the app tier to the db tier."
  type        = number

  validation {
    condition     = var.db_port >= 1 && var.db_port <= 65535
    error_message = "db_port must be between 1 and 65535."
  }
}
