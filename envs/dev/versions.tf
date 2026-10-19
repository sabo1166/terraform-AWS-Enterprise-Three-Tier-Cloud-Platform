terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Partial configuration: values come from backend.hcl (git-ignored), e.g.
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}
