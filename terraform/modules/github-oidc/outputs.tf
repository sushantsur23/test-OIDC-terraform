output "role_arn" {
  description = "Role ARN to put in the GitHub Actions workflow (AWS_ROLE_ARN)."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN."
  value       = local.oidc_provider_arn
}
