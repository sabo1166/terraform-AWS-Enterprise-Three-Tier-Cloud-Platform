variable "name" {
  description = "Name prefix for database resources."
  type        = string
}

variable "subnet_ids" {
  description = "Private database subnet IDs (one per AZ)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "A DB subnet group needs subnets in at least two AZs."
  }
}

variable "security_group_id" {
  description = "Database security group ID."
  type        = string
}

variable "engine_version" {
  description = "MySQL engine version (a major.minor such as \"8.0\" lets RDS pick the latest minor)."
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper bound in GiB for storage autoscaling. 0 disables autoscaling."
  type        = number
  default     = 0
}

variable "db_name" {
  description = "Name of the initial database."
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master password. Sensitive; supply via TF_VAR_db_password, never in a committed file. Ignored when manage_master_user_password is true. Note: it is stored in Terraform state."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Let RDS generate and store the master password in AWS Secrets Manager (keeps it out of Terraform state; small Secrets Manager cost)."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Deploy a standby in a second AZ. Improves availability; increases cost (about double the instance cost). Off by default."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to keep automated backups (0 disables them)."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent deletion of the DB instance."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on deletion. Leave false to keep a snapshot when the database is destroyed."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
