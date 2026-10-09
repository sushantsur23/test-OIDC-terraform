output "s3_bucket_names" {
  description = "Created S3 bucket names."
  value       = { for k, m in module.s3 : k => m.bucket_id }
}

output "secret_name" {
  description = "Secrets Manager secret to fill in."
  value       = module.app_secret.secret_name
}

output "secret_arn" {
  description = "Secrets Manager secret ARN."
  value       = module.app_secret.secret_arn
}

output "ec2_instance_id" {
  description = "EC2 instance ID (connect with: aws ssm start-session --target <id>)."
  value       = module.ec2.instance_id
}

output "ec2_private_ip" {
  description = "EC2 private IP."
  value       = module.ec2.private_ip
}
