locals {
  enabled = var.hosted_zone_id != "" && var.record_name != ""
}

# Alias record in an EXISTING hosted zone. This module never creates a zone or registers a domain.
resource "aws_route53_record" "alb_alias" {
  count = local.enabled ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
