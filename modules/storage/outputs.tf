output "bucket_name" {
  description = "Name of the private application S3 bucket."
  value       = aws_s3_bucket.app.id
}

output "bucket_arn" {
  description = "ARN of the private application S3 bucket."
  value       = aws_s3_bucket.app.arn
}
