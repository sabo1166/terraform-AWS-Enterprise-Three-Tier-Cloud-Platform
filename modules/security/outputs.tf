output "alb_security_group_id" {
  description = "Security group for the Application Load Balancer."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group for the application tier."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security group for the database tier."
  value       = aws_security_group.db.id
}
