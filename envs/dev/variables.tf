variable "region" {
  description = "AWS region for this environment."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
  default     = "three-tier"
}

variable "environment" {
  description = "Environment name (dev or prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "nat_mode" {
  description = "NAT Gateway strategy: single (one shared, cheaper) or per_az (one per AZ, resilient)."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_mode)
    error_message = "nat_mode must be single or per_az."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must be between /16 and /18 so each /24-/26 subnet carved from it is large enough for an ALB."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition = (
      can(cidrhost(var.vpc_cidr, 0)) &&
      tonumber(split("/", var.vpc_cidr)[1]) >= 16 &&
      tonumber(split("/", var.vpc_cidr)[1]) <= 18
    )
    error_message = "vpc_cidr must be a valid CIDR with a prefix length between /16 and /18."
  }
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on port 80. The default is open to the internet; restrict it (e.g. to your own IP/32) while testing."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.alb_ingress_cidrs) > 0 && alltrue([for c in var.alb_ingress_cidrs : can(cidrhost(c, 0))])
    error_message = "alb_ingress_cidrs must be a non-empty list of valid CIDR blocks."
  }
}

variable "app_port" {
  description = "TCP port the application listens on; allowed from the ALB to the app tier."
  type        = number
  default     = 80

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "db_port" {
  description = "TCP port of the database (MySQL default 3306); allowed from the app tier to the db tier."
  type        = number
  default     = 3306

  validation {
    condition     = var.db_port >= 1 && var.db_port <= 65535
    error_message = "db_port must be between 1 and 65535."
  }
}

variable "db_engine_version" {
  description = "MySQL engine version. A major.minor value (e.g. 8.0) lets RDS pick the latest minor and keep it patched; the parameter group family is derived from it."
  type        = string
  default     = "8.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$", var.db_engine_version))
    error_message = "db_engine_version must look like 8.0 or 8.0.40."
  }
}

variable "db_instance_class" {
  description = "RDS instance class. Main database cost driver; Graviton burstable classes are the cheapest."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Initial gp3 storage in GiB (20 is the RDS MySQL minimum)."
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "db_allocated_storage must be between 20 and 65536 GiB."
  }
}

variable "db_max_allocated_storage" {
  description = "Upper limit in GiB for storage autoscaling. 0 disables autoscaling."
  type        = number
  default     = 100

  validation {
    condition     = var.db_max_allocated_storage == 0 || var.db_max_allocated_storage >= var.db_allocated_storage
    error_message = "db_max_allocated_storage must be 0 (disabled) or at least db_allocated_storage."
  }
}

variable "db_name" {
  description = "Name of the initial database created in the instance."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,63}$", var.db_name))
    error_message = "db_name must start with a letter and contain only letters, digits and underscores (max 64)."
  }
}

variable "db_username" {
  description = "Master username. Not a secret; the password is generated and stored by RDS in Secrets Manager."
  type        = string
  default     = "dbadmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,15}$", var.db_username))
    error_message = "db_username must start with a letter and contain only letters, digits and underscores (max 16)."
  }
}

variable "db_multi_az" {
  description = "Run a synchronous standby in the second AZ. Roughly doubles instance cost; recommended for prod."
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Days to keep automated backups (0 disables backups and point-in-time recovery)."
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_days >= 0 && var.db_backup_retention_days <= 35
    error_message = "db_backup_retention_days must be between 0 and 35."
  }
}

variable "db_deletion_protection" {
  description = "Block deletion of the instance. The safe default is true; set false (and apply) before destroying."
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot when the instance is deleted. Keep false unless the data is disposable."
  type        = bool
  default     = false
}
