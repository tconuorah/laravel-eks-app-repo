variable "aws_region" {
  description = "AWS region where the Terraform backend resources will be created"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment label for bootstrap resources"
  type        = string
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state"
  type        = string
}

variable "state_bucket_force_destroy" {
  description = "When true, allow Terraform to delete all objects and versions so the state bucket can be destroyed"
  type        = bool
  default     = true
}
