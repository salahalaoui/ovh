resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = vault_auth_backend.this.path
  role_name                        = "app"
  bound_service_account_names      = ["webapp"]
  bound_service_account_namespaces = ["app"]
  token_ttl                        = 3600  # 1 hour
  token_policies                   = ["default", resource.vault_policy.webapp_policy.name]
  audience                         = "https://kubernetes.default.svc.cluster.local"  # Match the default K8s audience
}



resource "vault_policy" "webapp_policy" {
  name = "webapp-policy"

  policy = jsonencode({
    path = {
      # Grants read access to the data in the KVv2 secret path
      "kvv2/data/webapp/*" = {
        capabilities = ["read"]
      }
      # Grants list/read access to the metadata (required for lease management/rotation)
      "kvv2/metadata/webapp/*" = {
        capabilities = ["read", "list"]
      }
    }
  })
}