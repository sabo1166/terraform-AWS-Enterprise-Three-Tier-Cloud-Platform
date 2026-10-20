variable "hosted_zone_id" {
  description = "ID of an existing Route 53 hosted zone. Empty = no DNS record is created."
  type        = string
  default     = ""
}

variable "record_name" {
  description = "Fully qualified record name to point at the ALB (e.g. app.example.com). Empty = no DNS record is created."
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  description = "DNS name of the ALB."
  type        = string
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB (for the alias record)."
  type        = string
}
