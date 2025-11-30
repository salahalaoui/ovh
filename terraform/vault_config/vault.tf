
resource "vault_auth_backend" "this" {
  type = "kubernetes"
}

data "kubernetes_namespace" "vso" {
  metadata {
    name = "vault-secrets-operator-system"
  }
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend            = vault_auth_backend.this.path
  kubernetes_host    = "https://kubernetes.default.svc.cluster.local"
  # Use the dedicated vault-token-reviewer service account
  kubernetes_ca_cert = kubernetes_secret.vault_reviewer_token.data["ca.crt"]
  token_reviewer_jwt = kubernetes_secret.vault_reviewer_token.data["token"]
  disable_iss_validation = true
}

