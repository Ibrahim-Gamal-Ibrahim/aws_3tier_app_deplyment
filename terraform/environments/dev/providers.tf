terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform"
}