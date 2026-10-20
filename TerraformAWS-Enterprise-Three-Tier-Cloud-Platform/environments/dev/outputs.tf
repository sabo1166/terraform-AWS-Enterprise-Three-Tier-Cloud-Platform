output "vpc_id" {
  description = "ID of the VPC."
  value       = module.networking.vpc_id
}

output "availability_zones" {
  description = "The two Availability Zones in use."
  value       = module.networking.availability_zones
}

output "alb_dns_name" {
  description = "ALB DNS name (HTTP URL when allow_http_only is used, HTTPS otherwise)."
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "URL to reach the application."
  value       = local.https_enabled ? "https://${var.domain_name}" : "http://${module.alb.alb_dns_name}"
}

output "certificate_domain_validation_options" {
  description = "DNS records needed to validate the ACM certificate (relevant when no hosted_zone_id is supplied)."
  value       = module.acm.domain_validation_options
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = module.application.autoscaling_group_name
}

output "db_endpoint" {
  description = "RDS MySQL endpoint (reachable only from the application tier)."
  value       = module.database.endpoint
}

output "db_master_user_secret_arn" {
  description = "Secrets Manager ARN of the RDS-managed password (null unless db_manage_master_user_password is true)."
  value       = module.database.master_user_secret_arn
}
