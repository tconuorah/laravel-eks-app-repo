output "release_name" {
  value = helm_release.this.name
}

output "namespace" {
  value = helm_release.this.namespace
}

output "service_account_name" {
  value = var.service_account_name
}
