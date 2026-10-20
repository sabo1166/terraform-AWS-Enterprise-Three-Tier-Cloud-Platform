output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "availability_zones" {
  description = "The two Availability Zones in use, ordered [AZ-A, AZ-B]."
  value       = [local.azs["a"], local.azs["b"]]
}

output "public_subnet_ids" {
  description = "Public subnet IDs, ordered [AZ-A, AZ-B]."
  value       = [aws_subnet.public["a"].id, aws_subnet.public["b"].id]
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs, ordered [AZ-A, AZ-B]."
  value       = [aws_subnet.private_app["a"].id, aws_subnet.private_app["b"].id]
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs, ordered [AZ-A, AZ-B]."
  value       = [aws_subnet.private_db["a"].id, aws_subnet.private_db["b"].id]
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs (empty when NAT is disabled)."
  value       = [for k in sort(keys(aws_nat_gateway.this)) : aws_nat_gateway.this[k].id]
}
