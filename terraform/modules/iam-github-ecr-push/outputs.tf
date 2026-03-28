output "role_name" {
  value = aws_iam_role.this.name
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "policy_arn" {
  value = aws_iam_policy.this.arn
}

output "oidc_provider_arn" {
  value = local.oidc_provider_arn
}

output "allowed_subjects" {
  value = local.allowed_subjects
}
