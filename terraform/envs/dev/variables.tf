variable "ecr_repositories" {
  description = "ECR repositories keyed by container role"
  type        = map(string)
  default = {
    nginx = "nginx"
    php   = "php"
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the ECR push role, in owner/repo format"
  type        = string
  default     = "tconuorah/laravel-eks-deploy-gitops"
}

variable "github_allowed_refs" {
  description = "Git refs GitHub Actions can use to assume the ECR push role"
  type        = list(string)
  default     = ["refs/heads/dev"]
}

variable "create_github_oidc_provider" {
  description = "Whether Terraform should create the GitHub Actions OIDC provider in AWS"
  type        = bool
  default     = true
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN to reuse when create_github_oidc_provider is false"
  type        = string
  default     = null
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  type        = string
  default     = "argocd"
}

variable "external_secrets_namespace" {
  description = "Namespace where External Secrets Operator is installed"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_service_account_name" {
  description = "Service account name used by External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "laravel_namespace" {
  description = "Namespace for the Laravel workload"
  type        = string
  default     = "laravel"
}

variable "laravel_hostname" {
  description = "Public hostname for the Laravel application"
  type        = string
  default     = "laravel-dev.example.com"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "php-nginx-app"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type = list(string)
  default = [
    "us-east-2a",
    "us-east-2b"
  ]
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_app_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "private_db_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.small"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}


variable "db_name" {
  type    = string
  default = "laravel"
}

variable "db_username" {
  type    = string
  default = "root"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "rootpass"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}
