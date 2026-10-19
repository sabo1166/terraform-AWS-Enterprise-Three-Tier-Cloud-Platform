output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = module.network.vpc_cidr
}

output "availability_zones" {
  description = "Availability Zones in use, keyed az1/az2."
  value       = module.network.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB, NAT), keyed by AZ."
  value       = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  description = "Private application subnet IDs (EC2 Auto Scaling), keyed by AZ."
  value       = module.network.app_subnet_ids
}

output "db_subnet_ids" {
  description = "Private database subnet IDs (RDS), keyed by AZ."
  value       = module.network.db_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs, keyed by AZ (one entry in single mode, two in per_az mode)."
  value       = module.network.nat_gateway_ids
}

output "alb_security_group_id" {
  description = "Security group for the Application Load Balancer."
  value       = module.security.alb_security_group_id
}

output "app_security_group_id" {
  description = "Security group for the application tier."
  value       = module.security.app_security_group_id
}

output "db_security_group_id" {
  description = "Security group for the database tier."
  value       = module.security.db_security_group_id
}

output "app_bucket_name" {
  description = "Name of the private application S3 bucket."
  value       = module.storage.bucket_name
}

output "app_bucket_arn" {
  description = "ARN of the private application S3 bucket."
  value       = module.storage.bucket_arn
}

output "app_instance_role_arn" {
  description = "ARN of the IAM role assumed by application EC2 instances."
  value       = module.iam.role_arn
}

output "app_instance_profile_name" {
  description = "Name of the instance profile to attach to the app launch template."
  value       = module.iam.instance_profile_name
}

output "db_endpoint" {
  description = "Hostname of the RDS MySQL instance (private; resolves only inside the VPC)."
  value       = module.database.endpoint
}

output "db_port" {
  description = "Port the database listens on."
  value       = module.database.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = module.database.name
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = module.database.instance_arn
}

output "db_master_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials (the ARN only, never the value)."
  value       = module.database.master_secret_arn
}
