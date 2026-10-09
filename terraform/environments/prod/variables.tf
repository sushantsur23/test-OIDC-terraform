variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project name; prefixes resource names (must match bootstrap)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project))
    error_message = "project must be 3-24 chars of lowercase letters, digits or hyphens."
  }
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner tag."
  type        = string
}

variable "cost_center" {
  description = "CostCenter tag."
  type        = string
}

variable "github_repository" {
  description = "GitHub repo (owner/name), used as a tag."
  type        = string
}

variable "extra_tags" {
  description = "Additional tags for every resource."
  type        = map(string)
  default     = {}
}

# --- S3 ---------------------------------------------------------------------
variable "s3_buckets" {
  description = "Buckets to create. Map key becomes part of the bucket name."
  type = map(object({
    purpose                            = string
    versioning_enabled                 = optional(bool, true)
    noncurrent_version_expiration_days = optional(number, 90)
  }))
  default = {}
}

# --- Secrets Manager ----------------------------------------------------------
variable "secret_keys" {
  description = "Key names created in the secret with placeholder values."
  type        = list(string)
  default     = []
}

# --- EC2 ----------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID. Null = default VPC."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID. Null = first subnet of the VPC."
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Assign a public IP to the instance."
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 20
}

variable "ingress_rules" {
  description = "Security group inbound rules."
  type = list(object({
    description = string
    protocol    = string
    from_port   = number
    to_port     = number
    cidr        = string
  }))
  default = []
}
