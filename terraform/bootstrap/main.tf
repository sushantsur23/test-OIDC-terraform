# Run ONCE from your machine with admin credentials. It creates the IAM role
# that GitHub Actions assumes via OIDC; after that, the pipeline runs
# environments/prod without any stored AWS keys.

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Repository  = var.github_repository
    Stack       = "bootstrap"
  }
}

module "github_oidc" {
  source = "../modules/github-oidc"

  github_repository         = var.github_repository
  github_subject_repository = var.github_subject_repository
  role_name                 = "${var.project}-${var.environment}-github-actions"
  create_oidc_provider      = var.create_oidc_provider
  allowed_branches          = ["main"]
  allowed_environments      = [var.environment]
  allow_pull_requests       = true

  state_bucket         = var.state_bucket
  state_prefix         = var.state_prefix
  resource_name_prefix = var.project

  tags = { Component = "ci-cd" }
}
