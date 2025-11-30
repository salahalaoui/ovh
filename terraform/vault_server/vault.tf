# Create vault namespace
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

# Install Vault using Helm
resource "helm_release" "vault" {
  # Force recreation when storage config changes
  recreate_pods = true
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name

  values = [
    yamlencode({
      ui = {
        enabled     = true
        serviceType = "ClusterIP"  # ClusterIP for Gateway API
      }
      server = {
        # Explicitly disable dev mode
        dev = {
          enabled = false
        }
        # Production mode with high availability using Raft storage
        ha = {
          enabled  = true
          replicas = 1  # Start with 1, can scale to 3 for HA
          raft = {
            enabled = true
            setNodeId = true
            config = <<-EOT
              ui = true

              listener "tcp" {
                tls_disable = 1
                address = "[::]:8200"
                cluster_address = "[::]:8201"
              }

              storage "raft" {
                path = "/vault/data"
              }

              service_registration "kubernetes" {}
            EOT
          }
        }
        # Standalone mode is disabled when HA is enabled
        standalone = {
          enabled = false
        }
        # Data storage for Raft
        dataStorage = {
          enabled = true
          size = "10Gi"
          storageClass = null  # Use default storage class
        }
        # Audit storage
        auditStorage = {
          enabled = true
          size = "10Gi"
        }
      }
    })
  ]

  # Wait for deployment to be ready
  wait    = true
  timeout = 600

  # Force update to apply new values
  force_update = true
  cleanup_on_fail = true
}

