variable "name" {
  description = "Name prefix (the ALB and target group names must stay within 32 characters including suffix)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (one per AZ) for the ALB."
  type        = list(string)
}

variable "security_group_id" {
  description = "ALB security group ID."
  type        = string
}

variable "enable_https" {
  description = "Create the HTTPS listener and the HTTP->HTTPS redirect. Must be known at plan time (derive it from whether a domain is configured, not from the certificate ARN)."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of a validated ACM certificate in the ALB's region. Required when enable_https is true."
  type        = string
  default     = ""
}

variable "allow_http_only" {
  description = "Explicit DEVELOPMENT opt-in to serve plain HTTP (no TLS) when no certificate is configured."
  type        = bool
  default     = false
}

variable "ssl_policy" {
  description = "TLS security policy for the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "app_port" {
  description = "Port the targets listen on."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used for target health checks."
  type        = string
  default     = "/"
}

variable "enable_deletion_protection" {
  description = "Protect the ALB from accidental deletion."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
