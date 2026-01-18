
resource "vault_auth_backend" "this" {
  type = "kubernetes"
}

data "kubernetes_secret" "vault_reviewer_token" {
  metadata {
    namespace = "vault-secrets-operator-system"
    name      = "vault-token-reviewer"
  }
}


resource "vault_kubernetes_auth_backend_config" "this" {
  backend            = vault_auth_backend.this.path
  kubernetes_host    = "https://kubernetes.default.svc.cluster.local"
  # Use the dedicated vault-token-reviewer service account
  kubernetes_ca_cert = data.kubernetes_secret.vault_reviewer_token.data["ca.crt"]
  token_reviewer_jwt = data.kubernetes_secret.vault_reviewer_token.data["token"]
  disable_iss_validation = true
}

