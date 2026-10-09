# Non-secret values only. Never put secret values here — they go into
# Secrets Manager through the console or CLI.

aws_region        = "us-west-2"
project           = "sushant-app"
environment       = "prod"
owner             = "sushant"
cost_center       = "engineering"
github_repository = "sushantsur23/test-OIDC-terraform" # change me

extra_tags = {
  DataClassification = "internal"
}

# --- S3 buckets -------------------------------------------------------------
# Name becomes: sushant-app-prod-<key>-<account-id>
s3_buckets = {
  app-data = {
    purpose = "application-data"
  }
  logs = {
    purpose                            = "logs"
    noncurrent_version_expiration_days = 30
  }
}

# --- Secrets Manager ----------------------------------------------------------
# Created as {"DB_HOST":"CHANGE_ME", ...}; fill real values afterwards.
secret_keys = [
  "DB_HOST",
  "DB_USERNAME",
  "DB_PASSWORD",
  "API_KEY",
]

# --- EC2 ----------------------------------------------------------------------
instance_type       = "t3.micro"
associate_public_ip = false
root_volume_size    = 20

# No inbound rules: connect through SSM Session Manager.
# Example to allow HTTPS from anywhere:
# ingress_rules = [
#   { description = "HTTPS", protocol = "tcp", from_port = 443, to_port = 443, cidr = "0.0.0.0/0" }
# ]
ingress_rules = []
