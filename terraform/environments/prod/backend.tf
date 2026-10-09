# State:  s3://remote-test-sushant/prod/terraform-lock/terraform.tfstate
# Lock:   s3://remote-test-sushant/prod/terraform-lock/terraform.tfstate.tflock
#
# The bucket uses SSE-S3, so `encrypt = true` is enough (no kms_key_id).
# use_lockfile = native S3 locking (Terraform >= 1.10), no DynamoDB table.

terraform {
  backend "s3" {
    bucket       = "remote-test-sushant"
    key          = "prod/terraform-lock/terraform.tfstate"
    region       = "us-west-2" # change to your bucket's region
    encrypt      = true
    use_lockfile = true
  }
}
