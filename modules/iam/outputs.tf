output "role_arn" {
  description = "ARN of the IAM role assumed by application EC2 instances."
  value       = aws_iam_role.app.arn
}

output "role_name" {
  description = "Name of the IAM role assumed by application EC2 instances."
  value       = aws_iam_role.app.name
}

output "instance_profile_name" {
  description = "Name of the instance profile to attach to the app launch template."
  value       = aws_iam_instance_profile.app.name
}
