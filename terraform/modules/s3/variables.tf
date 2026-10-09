variable "bucket_name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "versioning_enabled" {
  description = "Enable object versioning."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS. Leave null to use SSE-S3 (AES256)."
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Delete noncurrent versions after N days (0 = keep forever)."
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Allow terraform destroy to delete a non-empty bucket. Keep false in prod."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource-specific tags (common tags come from the provider's default_tags)."
  type        = map(string)
  default     = {}
}
