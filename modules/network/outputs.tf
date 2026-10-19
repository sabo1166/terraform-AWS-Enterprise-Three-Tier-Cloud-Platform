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
