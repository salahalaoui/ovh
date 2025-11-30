resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}




data "kubernetes_service_account" "this" {
  metadata {
    name      = "webapp"
    namespace = resource.kubernetes_namespace.app.id
  }
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = vault_auth_backend.this.path
  role_name                        = "app"
  bound_service_account_names      = [data.kubernetes_service_account.this.metadata[0].name]
  bound_service_account_namespaces = [resource.kubernetes_namespace.app.metadata[0].name]
  token_ttl                        = 3600  # 1 hour
  token_policies                   = ["default"]
  audience                         = "https://kubernetes.default.svc.cluster.local"  # Match the default K8s audience
}