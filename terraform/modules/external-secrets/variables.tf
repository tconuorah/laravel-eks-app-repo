variable "release_name" {
  type    = string
  default = "external-secrets"
}

variable "namespace" {
  type    = string
  default = "external-secrets"
}

variable "service_account_name" {
  type    = string
  default = "external-secrets"
}

variable "chart_version" {
  type    = string
  default = "1.2.1"
}

variable "irsa_role_arn" {
  type = string
}
