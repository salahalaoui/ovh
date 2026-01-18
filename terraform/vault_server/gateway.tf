# Standard LoadBalancer Service for Vault UI
resource "kubernetes_service" "vault_lb" {
  metadata {
    name      = "vault-ui-lb2"
    namespace = kubernetes_namespace.vault.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/ovh-loadbalancer-balance" = "roundrobin"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "vault"
      "app.kubernetes.io/instance" = helm_release.vault.name
      "component"                  = "server"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8200
    }

    type = "LoadBalancer"
  }

}
