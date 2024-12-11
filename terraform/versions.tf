provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "get_me_out_of_here"
      Owner       = "Todd"
      Provisioner = "Terraform"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.80.0"
    }
  }
  required_version = "1.10.1"
}