variable "name_prefix" {
  description = "Prefix for resource names, e.g. three-tier-dev."
  type        = string
}

variable "subnet_ids" {
  description = "Private database subnet IDs (at least two, in different AZs) for the DB subnet group."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to the database; should allow the DB port only from the app tier."
  type        = string
}

variable "db_port" {
  description = "TCP port the database listens on (MySQL default 3306)."
  type        = number

  validation {
    condition     = var.db_port >= 1 && var.db_port <= 65535
    error_message = "db_port must be between 1 and 65535."
  }
}

variable "db_engine_version" {
  description = "MySQL engine version. A major.minor value (e.g. 8.0) lets RDS pick the latest minor and keep it patched; the parameter group family is derived from it."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$", var.db_engine_version))
    error_message = "db_engine_version must look like 8.0 or 8.0.40."
  }
}

variable "db_instance_class" {
  description = "RDS instance class. Main database cost driver; Graviton burstable classes are the cheapest."
  type        = string
}

variable "db_allocated_storage" {
  description = "Initial gp3 storage in GiB (20 is the RDS MySQL minimum)."
  type        = number

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "db_allocated_storage must be between 20 and 65536 GiB."
  }
}

variable "db_max_allocated_storage" {
  description = "Upper limit in GiB for storage autoscaling. 0 disables autoscaling."
  type        = number

  validation {
    condition     = var.db_max_allocated_storage == 0 || var.db_max_allocated_storage >= var.db_allocated_storage
    error_message = "db_max_allocated_storage must be 0 (disabled) or at least db_allocated_storage."
  }
}

variable "db_name" {
  description = "Name of the initial database created in the instance."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,63}$", var.db_name))
    error_message = "db_name must start with a letter and contain only letters, digits and underscores (max 64)."
  }
}

variable "db_username" {
  description = "Master username. Not a secret; the password is generated and stored by RDS in Secrets Manager."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,15}$", var.db_username))
    error_message = "db_username must start with a letter and contain only letters, digits and underscores (max 16)."
  }
}

variable "db_multi_az" {
  description = "Run a synchronous standby in the second AZ. Roughly doubles instance cost; recommended for prod."
  type        = bool
}

variable "db_backup_retention_days" {
  description = "Days to keep automated backups (0 disables backups and point-in-time recovery)."
  type        = number

  validation {
    condition     = var.db_backup_retention_days >= 0 && var.db_backup_retention_days <= 35
    error_message = "db_backup_retention_days must be between 0 and 35."
  }
}

variable "db_deletion_protection" {
  description = "Block deletion of the instance. The safe default is true; set false (and apply) before destroying."
  type        = bool
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot when the instance is deleted. Keep false unless the data is disposable."
  type        = bool
}
