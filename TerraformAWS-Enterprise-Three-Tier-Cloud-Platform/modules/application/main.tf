data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-${var.architecture}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Optional: shell access through SSM Session Manager instead of SSH.
# Needs outbound HTTPS (provided by the NAT Gateway).
resource "aws_iam_role" "instance" {
  count = var.enable_ssm ? 1 : 0

  name_prefix = "${var.name}-app-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  count = var.enable_ssm ? 1 : 0

  name_prefix = "${var.name}-app-"
  role        = aws_iam_role.instance[0].name

  tags = var.tags
}
