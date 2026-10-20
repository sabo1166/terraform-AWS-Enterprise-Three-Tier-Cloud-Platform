output "alb_arn" {
  description = "ARN of the ALB."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB (for Route 53 alias records)."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.app.arn
}
