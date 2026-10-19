output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
  description = "Availability Zones in use, keyed az1/az2."
  value       = { for k, v in local.az_map : k => v.name }
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB, NAT), keyed by AZ."
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "app_subnet_ids" {
  description = "Private application subnet IDs (EC2 Auto Scaling), keyed by AZ."
  value       = { for k, s in aws_subnet.app : k => s.id }
}

output "db_subnet_ids" {
  description = "Private database subnet IDs (RDS), keyed by AZ."
  value       = { for k, s in aws_subnet.db : k => s.id }
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs, keyed by AZ (one entry in single mode, two in per_az mode)."
  value       = { for k, n in aws_nat_gateway.main : k => n.id }
}

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

output "app_bucket_name" {
  description = "Name of the private application S3 bucket."
  value       = aws_s3_bucket.app.id
}

output "app_bucket_arn" {
  description = "ARN of the private application S3 bucket."
  value       = aws_s3_bucket.app.arn
}

output "app_instance_role_arn" {
  description = "ARN of the IAM role assumed by application EC2 instances."
  value       = aws_iam_role.app.arn
}

output "app_instance_profile_name" {
  description = "Name of the instance profile to attach to the app launch template."
  value       = aws_iam_instance_profile.app.name
}

output "db_endpoint" {
  description = "Hostname of the RDS MySQL instance (private; resolves only inside the VPC)."
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Port the database listens on."
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.main.db_name
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.main.arn
}

output "db_master_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials (the ARN only, never the value)."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
