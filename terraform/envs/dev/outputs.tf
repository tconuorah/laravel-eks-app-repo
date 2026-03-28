output "ecr_repository_urls" {
  value = {
    for key, repository in module.ecr : key => repository.repository_url
  }
}

output "ecr_repository_names" {
  value = {
    for key, repository in module.ecr : key => repository.repository_name
  }
}

output "github_ecr_push_role_arn" {
  value = module.github_ecr_push_role.role_arn
}

output "github_oidc_provider_arn" {
  value = module.github_ecr_push_role.oidc_provider_arn
}

output "github_ecr_push_allowed_subjects" {
  value = module.github_ecr_push_role.allowed_subjects
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds_mysql.db_endpoint
}
