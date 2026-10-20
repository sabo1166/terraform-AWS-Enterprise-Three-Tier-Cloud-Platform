output "certificate_arn" {
  description = "ARN of the validated certificate, or an empty string when no domain is configured."
  value       = local.enabled ? aws_acm_certificate_validation.this[0].certificate_arn : ""
}

output "domain_validation_options" {
  description = "DNS records required to validate the certificate (create manually when no hosted zone is supplied)."
  value = local.enabled ? [
    for dvo in aws_acm_certificate.this[0].domain_validation_options : {
      domain_name = dvo.domain_name
      name        = dvo.resource_record_name
      type        = dvo.resource_record_type
      value       = dvo.resource_record_value
    }
  ] : []
}
