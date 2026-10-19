variable "name_prefix" {
  description = "Prefix for resource names, e.g. three-tier-dev."
  type        = string
}

variable "app_bucket_arn" {
  description = "ARN of the application S3 bucket the instances may read and write."
  type        = string
}

variable "db_secret_arn" {
  description = "Exact ARN of the Secrets Manager secret holding the RDS master credentials."
  type        = string
}
