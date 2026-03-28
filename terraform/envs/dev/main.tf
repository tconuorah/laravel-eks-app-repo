locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "ecr" {
  for_each = var.ecr_repositories

  source = "../../modules/ecr"
  name   = each.value
  tags   = local.tags
}

module "github_ecr_push_role" {
  source = "../../modules/iam-github-ecr-push"

  role_name            = "${local.name}-github-ecr-push"
  github_repositories  = [var.github_repository]
  github_refs          = var.github_allowed_refs
  ecr_repository_arns  = [for repository in values(module.ecr) : repository.repository_arn]
  create_oidc_provider = var.create_github_oidc_provider
  oidc_provider_arn    = var.github_oidc_provider_arn
  tags                 = local.tags
}

module "vpc" {
  source = "../../modules/vpc"

  name                     = local.name
  vpc_cidr                 = var.vpc_cidr
  azs                      = var.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  cluster_name             = local.name
  tags                     = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = local.name
  cluster_version     = var.cluster_version
  subnet_ids          = module.vpc.private_app_subnet_ids
  vpc_id              = module.vpc.vpc_id
  node_instance_types = var.node_instance_types
  desired_size        = var.desired_size
  min_size            = var.min_size
  max_size            = var.max_size
  tags                = local.tags
}

module "irsa_alb_controller" {
  source = "../../modules/irsa-alb-controller"

  cluster_name         = module.eks.cluster_name
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespace            = "kube-system"
  service_account_name = "aws-load-balancer-controller"
  tags                 = local.tags
}

module "alb_controller" {
  source = "../../modules/alb-controller"

  cluster_name              = module.eks.cluster_name
  region                    = var.aws_region
  vpc_id                    = module.vpc.vpc_id
  service_account_name      = "aws-load-balancer-controller"
  service_account_namespace = "kube-system"
  irsa_role_arn             = module.irsa_alb_controller.role_arn

  depends_on = [
    module.eks,
    module.irsa_alb_controller
  ]
}

module "rds_mysql" {
  source = "../../modules/rds-mysql"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  db_subnet_ids      = module.vpc.private_db_subnet_ids
  app_security_group = module.eks.node_security_group_id
  app_cidr_blocks    = var.private_app_subnet_cidrs
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  db_instance_class  = var.db_instance_class
  tags               = local.tags
}
