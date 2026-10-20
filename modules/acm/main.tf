locals {
  enabled = var.domain_name != ""
}

# Must be created in the same region as the ALB (the provider region of the caller).
resource "aws_acm_certificate" "this" {
  count = local.enabled ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  tags = merge(var.tags, { Name = var.domain_name })

  lifecycle {
    create_before_destroy = true
  }
}

# Validation CNAMEs are created only when an existing hosted zone is supplied.
# Otherwise create them manually at your DNS provider (see the
# domain_validation_options output) while `terraform apply` waits.
resource "aws_route53_record" "validation" {
  for_each = local.enabled && var.hosted_zone_id != "" ? {
    for dvo in aws_acm_certificate.this[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = var.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Blocks until the certificate is ISSUED, so the ALB never gets an unvalidated ARN.
resource "aws_acm_certificate_validation" "this" {
  count = local.enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = var.hosted_zone_id != "" ? [for r in aws_route53_record.validation : r.fqdn] : null

  timeouts {
    create = var.validation_timeout
  }
}
