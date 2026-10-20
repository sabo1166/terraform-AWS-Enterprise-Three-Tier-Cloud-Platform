resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-app-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  # No key pair and no SSH: there is no inbound path other than the ALB.
  vpc_security_group_ids = [var.security_group_id]
  user_data              = filebase64("${path.module}/user_data/nginx.sh")
  update_default_version = true

  dynamic "iam_instance_profile" {
    for_each = var.enable_ssm ? [1] : []
    content {
      name = aws_iam_instance_profile.instance[0].name
    }
  }

  # IMDSv2 only.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = false # basic (5-minute) monitoring; detailed monitoring is billable
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-app" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.name}-app" })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
