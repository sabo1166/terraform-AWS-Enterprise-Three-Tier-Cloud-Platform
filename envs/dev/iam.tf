# IAM for the application EC2 instances (used by the Auto Scaling launch
# template in a later phase). No AdministratorAccess and no broad managed
# policies: permissions are two small inline policies below.

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${local.name_prefix}-app-ec2-role"
  description        = "Application EC2 instances: SSM Session Manager and access to the app bucket"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = { Name = "${local.name_prefix}-app-ec2-role" }
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-app-ec2-profile"
  role = aws_iam_role.app.name

  tags = { Name = "${local.name_prefix}-app-ec2-profile" }
}

# --- SSM Session Manager (shell access with no SSH/keys/open ports) -----------
# Exactly the actions AWS documents for a custom Session Manager instance
# profile. The wildcard Resource is unavoidable: these actions do not support
# resource-level scoping (the agent calls them before any ARN exists to name).
# Not included: ec2messages:* / Run Command / Patch Manager. Add them later only
# if those features are needed.
data "aws_iam_policy_document" "ssm_session" {
  statement {
    sid    = "SessionManagerAgent"
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ssm_session" {
  name   = "ssm-session-manager"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.ssm_session.json
}

# --- App bucket access ---------------------------------------------------------
# Read/write objects and list, on this one bucket only. No delete, no bucket
# management, no access to any other bucket.
data "aws_iam_policy_document" "app_bucket_access" {
  statement {
    sid       = "ListAppBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app.arn]
  }

  statement {
    sid       = "ReadWriteAppObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.app.arn}/*"]
  }
}

resource "aws_iam_role_policy" "app_bucket_access" {
  name   = "app-bucket-access"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_bucket_access.json
}

# --- Database credentials -------------------------------------------------------
# Read only the Secrets Manager secret RDS created for this instance's master
# password, by its exact ARN (the random suffix is part of the attribute, so no
# wildcard is needed). The secret uses the default aws/secretsmanager key, which
# needs no separate kms:Decrypt grant for principals in the same account.
data "aws_iam_policy_document" "db_secret_read" {
  statement {
    sid    = "ReadDbMasterSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_db_instance.main.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "db_secret_read" {
  name   = "db-master-secret-read"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.db_secret_read.json
}
