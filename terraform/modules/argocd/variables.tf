variable "release_name" {
  type    = string
  default = "argocd"
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  type    = string
  default = "9.2.4"
}

variable "server_service_type" {
  type    = string
  default = "ClusterIP"
}
