variable "name" {
  description = "Name prefix for application resources."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private application subnet IDs (one per AZ) for the Auto Scaling Group."
  type        = list(string)
}

variable "security_group_id" {
  description = "Application security group ID."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group to register instances with."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "architecture" {
  description = "AMI architecture; must match instance_type (x86_64 or arm64)."
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture must be x86_64 or arm64."
  }
}

variable "min_size" {
  description = "Minimum number of instances. Keep at 2 to retain AZ resilience."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances."
  type        = number
  default     = 4
}

variable "cpu_target_utilization" {
  description = "Average CPU percentage the target-tracking scaling policy aims for."
  type        = number
  default     = 60
}

variable "health_check_grace_period" {
  description = "Seconds to wait after launch before ELB health checks count (covers user-data install time)."
  type        = number
  default     = 300
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB (encrypted gp3)."
  type        = number
  default     = 8
}

variable "enable_ssm" {
  description = "Attach an IAM role with AmazonSSMManagedInstanceCore so instances can be reached via SSM Session Manager (no SSH needed)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
