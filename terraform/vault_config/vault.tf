resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}

# Application service account (for nginx/app pods) - NO TokenReview permission
resource "kubernetes_service_account" "this" {
  metadata {
    name      = "terraform"
    namespace = kubernetes_namespace.app.id
  }
}

# Dedicated service account ONLY for Vault to validate tokens
resource "kubernetes_service_account" "vault_reviewer" {
  metadata {
    name      = "vault-token-reviewer"
    namespace = kubernetes_namespace.app.id
  }
}

# Token for the vault-token-reviewer service account
resource "kubernetes_secret" "vault_reviewer_token" {
  metadata {
    name      = "vault-token-reviewer-secret"
    namespace = kubernetes_namespace.app.id
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.vault_reviewer.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

# ClusterRole: Permission to create TokenReviews
resource "kubernetes_cluster_role" "token_reviewer" {
  metadata {
    name = "vault-token-reviewer"
  }

  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }
}

# Bind the ClusterRole to vault-token-reviewer service account
resource "kubernetes_cluster_role_binding" "token_reviewer" {
  metadata {
    name = "vault-token-reviewer-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.token_reviewer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault_reviewer.metadata[0].name
    namespace = kubernetes_namespace.app.id
  }
}

resource "vault_auth_backend" "this" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend            = vault_auth_backend.this.path
  kubernetes_host    = "https://kubernetes.default.svc.cluster.local"
  # Use the dedicated vault-token-reviewer service account
  kubernetes_ca_cert = kubernetes_secret.vault_reviewer_token.data["ca.crt"]
  token_reviewer_jwt = kubernetes_secret.vault_reviewer_token.data["token"]
  disable_iss_validation = true
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = vault_auth_backend.this.path
  role_name                        = "app"
  bound_service_account_names      = [kubernetes_service_account.this.metadata[0].name]
  bound_service_account_namespaces = [kubernetes_namespace.app.metadata[0].name]
  token_ttl                        = 3600  # 1 hour
  token_policies                   = ["default"]
  audience                         = "https://kubernetes.default.svc.cluster.local"  # Match the default K8s audience
}