# Dedicated service account ONLY for Vault to validate tokens
resource "kubernetes_service_account" "vault_reviewer" {
  metadata {
    name      = "vault-token-reviewer"
    namespace = data.kubernetes_namespace.vso.id
  }
}

# Token for the vault-token-reviewer service account
resource "kubernetes_secret" "vault_reviewer_token" {
  metadata {
    name      = "vault-token-reviewer-secret"
    namespace = data.kubernetes_namespace.vso.id
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
    namespace = data.kubernetes_namespace.vso.id
  }
}