variable "name" {
  description = "Name prefix for security groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC in which the security groups are created."
  type        = string
}

variable "enable_https" {
  description = "Open port 443 on the ALB security group. Set true only when an HTTPS listener exists."
  type        = bool
  default     = false
}

variable "alb_ingress_cidrs" {
  description = "Client CIDRs allowed to reach the public ALB on 80/443. The ALB is internet-facing by design; restrict this (e.g. to your office IP) for non-public environments."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Port the application listens on."
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Port the database listens on."
  type        = number
  default     = 3306
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
