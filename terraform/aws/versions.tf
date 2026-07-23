terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Day-3 task: enable remote state (you already run this pattern).
  # backend "s3" {
  #   bucket         = "<your-tf-state-bucket>"
  #   key            = "multi-cloud-platform/aws/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "<your-lock-table>"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = "multi-cloud-gitops-platform"
      ManagedBy = "terraform"
    }
  }
}
