resource "helm_release" "this" {
  name       = var.release_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true

  set {
    name  = "server.service.type"
    value = var.server_service_type
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }
}
