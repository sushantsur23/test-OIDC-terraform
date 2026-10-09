variable "name" {
  description = "Secret name, e.g. myapp/prod/app-config."
  type        = string
}

variable "description" {
  description = "Secret description."
  type        = string
  default     = "Managed by Terraform. Values are set outside Terraform."
}

variable "secret_keys" {
  description = "Key names to create with placeholder values (fill real values in the console/CLI)."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN. Null uses the AWS-managed key."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days before a deleted secret is permanently removed (0 or 7-30)."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Resource-specific tags."
  type        = map(string)
  default     = {}
}
