variable "region" {
  description = "AWS region for all resources (the ACM certificate is created in the same region as the ALB)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as a prefix for resource names and tags. Kept short because ALB and target group names are limited to 32 characters."
  type        = string
  default     = "three-tier"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,16}$", var.project_name))
    error_message = "project_name must be 3-16 characters: lowercase letters, digits, hyphens."
  }
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.environment))
    error_message = "environment must be 2-8 lowercase letters or digits."
  }
}

# ---- Networking -----------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs [AZ-A, AZ-B]."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private application subnet CIDRs [AZ-A, AZ-B]."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDRs [AZ-A, AZ-B]."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway(s). Billable. Without NAT the private instances cannot install Nginx."
  type        = bool
  default     = true
}

variable "nat_gateway_mode" {
  description = "\"single\" (one NAT, cheapest, dev default) or \"per_az\" (one NAT per AZ, higher availability, about double the NAT cost)."
  type        = string
  default     = "single"
}

# ---- Ingress / TLS / DNS --------------------------------------------------
variable "alb_ingress_cidrs" {
  description = "Client CIDRs allowed to reach the public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Domain for the ACM certificate and Route 53 alias (e.g. app.example.com). Empty = no certificate, no HTTPS, no DNS record."
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Extra names on the certificate."
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "ID of an EXISTING Route 53 hosted zone that contains domain_name. Empty = certificate validation records and the alias record are not created by Terraform."
  type        = string
  default     = ""

  validation {
    condition     = var.hosted_zone_id == "" || var.domain_name != ""
    error_message = "hosted_zone_id is only used together with domain_name; set domain_name or clear hosted_zone_id."
  }
}

variable "allow_http_only" {
  description = "Development opt-in to serve plain HTTP (no encryption) when domain_name is empty. Never use for production."
  type        = bool
  default     = false
}

variable "alb_deletion_protection" {
  description = "Enable ALB deletion protection."
  type        = bool
  default     = false
}

# ---- Application ----------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type for the application tier."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "ASG minimum size (2 keeps one instance per AZ)."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG maximum size."
  type        = number
  default     = 4
}

variable "enable_ssm" {
  description = "Attach the SSM managed-instance role for Session Manager access (no SSH)."
  type        = bool
  default     = false
}

# ---- Database -------------------------------------------------------------
variable "db_engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GiB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username."
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "RDS master password. Provide via the TF_VAR_db_password environment variable (never in a committed file). Not needed when db_manage_master_user_password is true."
  type        = string
  default     = null
  sensitive   = true
}

variable "db_manage_master_user_password" {
  description = "Let RDS generate the master password in AWS Secrets Manager instead of supplying db_password."
  type        = bool
  default     = false
}

variable "db_multi_az" {
  description = "Enable RDS Multi-AZ. Better availability, higher cost. Off by default."
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Days to retain automated RDS backups."
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot when the database is destroyed (data is then unrecoverable)."
  type        = bool
  default     = false
}
