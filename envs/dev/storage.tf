data "aws_caller_identity" "current" {}

locals {
  # Account ID and region make the globally unique bucket name collision-free
  # without a random suffix (and keep it stable across plans).
  app_bucket_name = "${local.name_prefix}-app-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

# Private application bucket (uploads, artifacts, static config).
# Note: no force_destroy, so Terraform refuses to delete a non-empty bucket.
resource "aws_s3_bucket" "app" {
  bucket = local.app_bucket_name

  tags = { Name = local.app_bucket_name }
}

# Disable ACLs entirely; access is controlled only by IAM and the bucket policy.
resource "aws_s3_bucket_ownership_controls" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3 (AES-256, AWS-managed keys): no KMS cost or key policy to manage.
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "app_bucket" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.app.arn, "${aws_s3_bucket.app.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Also reject TLS 1.0/1.1 clients.
  statement {
    sid       = "DenyOldTlsVersions"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.app.arn, "${aws_s3_bucket.app.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.app_bucket.json

  # Applying a policy while public-access settings are mid-change can fail.
  depends_on = [aws_s3_bucket_public_access_block.app]
}
