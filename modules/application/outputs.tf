output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "ID of the Launch Template."
  value       = aws_launch_template.app.id
}

output "ami_id" {
  description = "Amazon Linux 2023 AMI used by the Launch Template."
  value       = data.aws_ami.al2023.id
}
