variable "role_name" {
  description = "IAM role name for GitHub Actions ECR pushes"
  type        = string
}

variable "github_repositories" {
  description = "GitHub repositories allowed to assume the role, in owner/repo format"
  type        = list(string)

  validation {
    condition     = length(var.github_repositories) > 0
    error_message = "Provide at least one GitHub repository."
  }
}

variable "github_refs" {
  description = "Git refs allowed to assume the role, for example refs/heads/dev or refs/tags/v1.0.0"
  type        = list(string)
  default     = ["refs/heads/main"]

  validation {
    condition     = length(var.github_refs) > 0
    error_message = "Provide at least one Git ref."
  }
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the role can push to"
  type        = list(string)

  validation {
    condition     = length(var.ecr_repository_arns) > 0
    error_message = "Provide at least one ECR repository ARN."
  }
}

variable "create_oidc_provider" {
  description = "Whether to create the GitHub Actions IAM OIDC provider in this account"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN to reuse when create_oidc_provider is false"
  type        = string
  default     = null
}

variable "oidc_provider_url" {
  description = "GitHub Actions OIDC provider URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "tags" {
  description = "Tags applied to IAM resources"
  type        = map(string)
  default     = {}
}
