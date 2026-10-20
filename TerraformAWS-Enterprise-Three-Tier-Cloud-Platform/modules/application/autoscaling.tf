resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.name}-app-"
  vpc_zone_identifier = var.private_subnet_ids # both private app subnets => both AZs
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size

  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # Replace instances (keeping at least 50% healthy) when the launch template changes.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.min_size <= var.desired_capacity && var.desired_capacity <= var.max_size
      error_message = "Capacity must satisfy min_size <= desired_capacity <= max_size."
    }
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_utilization
  }
}
