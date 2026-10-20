variable "domain_name" {
  description = "Primary domain name for the certificate. Empty string disables the module (no certificate is created)."
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Additional names on the certificate."
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "ID of an EXISTING Route 53 public hosted zone used to publish DNS validation records. Empty = validation records must be created manually."
  type        = string
  default     = ""
}

variable "validation_timeout" {
  description = "How long to wait for the certificate to be issued."
  type        = string
  default     = "45m"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
