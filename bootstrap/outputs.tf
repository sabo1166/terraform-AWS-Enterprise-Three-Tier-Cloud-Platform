output "state_bucket_name" {
  description = "Name of the S3 bucket to use in each environment's backend.hcl."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_region" {
  description = "Region of the state bucket."
  value       = var.region
}
