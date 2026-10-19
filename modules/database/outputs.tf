output "endpoint" {
  description = "Hostname of the RDS MySQL instance (private; resolves only inside the VPC)."
  value       = aws_db_instance.main.address
}

output "port" {
  description = "Port the database listens on."
  value       = aws_db_instance.main.port
}

output "name" {
  description = "Name of the initial database."
  value       = aws_db_instance.main.db_name
}

output "instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.main.arn
}

output "master_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials (the ARN only, never the value)."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
