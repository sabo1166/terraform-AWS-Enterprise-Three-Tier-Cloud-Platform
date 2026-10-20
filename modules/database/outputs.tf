output "endpoint" {
  description = "Connection endpoint (host:port)."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname of the DB instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port of the DB instance."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN of the RDS-managed master password (null unless manage_master_user_password is true)."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}
