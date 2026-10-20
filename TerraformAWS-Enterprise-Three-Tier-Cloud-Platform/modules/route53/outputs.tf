output "record_fqdn" {
  description = "FQDN of the alias record, or an empty string when DNS is not configured."
  value       = local.enabled ? aws_route53_record.alb_alias[0].fqdn : ""
}
