resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  description             = var.description
  kms_key_id              = var.kms_key_arn # null = AWS-managed key aws/secretsmanager
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, { Name = var.name })
}

# Creates the secret with placeholder keys only. You fill in the real values
# in the AWS console/CLI; ignore_changes stops Terraform from overwriting them
# and keeps real secret values out of your code and tfvars.
resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({ for k in var.secret_keys : k => "CHANGE_ME" })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
