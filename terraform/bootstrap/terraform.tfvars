aws_region        = "us-west-2"
project           = "sushant-app"
environment       = "prod"
owner             = "sushant"
cost_center       = "engineering"
github_repository = "sushantsur23/test-OIDC-terraform" # change me

# GitHub sends this immutable form in the OIDC sub claim (seen in CloudTrail).
github_subject_repository = "sushantsur23@77981264/test-OIDC-terraform@1410384574"

# Set to false if your AWS account already has the GitHub OIDC provider.
create_oidc_provider = false
