variable "github_repository" {
  description = "GitHub repository in owner/name form, e.g. sushant/infra."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must look like owner/repo."
  }
}

variable "github_subject_repository" {
  description = "Repo identifier used in the OIDC sub claim, if it differs from github_repository, e.g. owner@123/repo@456. Find it in CloudTrail AssumeRoleWithWebIdentity events. Null uses github_repository."
  type        = string
  default     = null
}

variable "role_name" {
  description = "Name of the IAM role GitHub Actions assumes."
  type        = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider (only one is allowed per account)."
  type        = bool
  default     = true
}

variable "allowed_branches" {
  description = "Branches whose workflow runs may assume the role."
  type        = list(string)
  default     = ["main"]
}

variable "allowed_environments" {
  description = "GitHub Environments whose jobs may assume the role."
  type        = list(string)
  default     = ["prod"]
}

variable "allow_pull_requests" {
  description = "Allow pull_request workflows (for terraform plan) to assume the role."
  type        = bool
  default     = true
}

variable "state_bucket" {
  description = "S3 bucket holding Terraform state."
  type        = string
}

variable "state_prefix" {
  description = "Prefix (directory) in the state bucket the role may read/write, without trailing slash."
  type        = string
}

variable "resource_name_prefix" {
  description = "IAM roles/instance profiles the pipeline may manage must start with this prefix."
  type        = string
}

variable "managed_policy_arns" {
  description = "AWS managed policies to attach for provisioning resources. Tighten for least privilege."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/PowerUserAccess"]
}

variable "tags" {
  description = "Resource-specific tags."
  type        = map(string)
  default     = {}
}
