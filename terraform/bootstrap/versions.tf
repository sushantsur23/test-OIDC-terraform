terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }

  # Bootstrap state sits next to the prod state, in its own file.
  backend "s3" {
    bucket       = "remote-test-sushant"
    key          = "prod/terraform-lock/bootstrap/terraform.tfstate"
    region       = "us-west-2" # change to your bucket's region
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
