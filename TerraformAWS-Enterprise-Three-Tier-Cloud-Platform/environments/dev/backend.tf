# Existing state bucket (NOT created by this project). It must already exist,
# in the region below, with versioning enabled and access for your credentials.
# No credentials belong here: they come from the environment / AWS profile.
terraform {
  backend "s3" {
    bucket       = "states.tf-2026-test-1"
    key          = "enterprise-three-tier/dev/terraform.tfstate"
    encrypt      = true
    use_lockfile = true # S3-native locking; no DynamoDB table

    # Region evidence: an unauthenticated HEAD request to the S3 endpoint for this
    # bucket returned 403 with "x-amz-bucket-region: us-east-1" (so the bucket
    # exists there). That does NOT prove it belongs to your AWS account; confirm
    # with valid credentials (see README). If it differs, fix this value or run:
    #   terraform init -backend-config="region=<bucket-region>"
    region = "us-east-1"
  }
}
