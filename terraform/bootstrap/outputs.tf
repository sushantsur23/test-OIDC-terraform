output "github_actions_role_arn" {
  description = "Add this as the AWS_ROLE_ARN variable in GitHub (Settings > Environments > prod)."
  value       = module.github_oidc.role_arn
}
