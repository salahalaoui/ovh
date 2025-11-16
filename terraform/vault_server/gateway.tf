# Install Traefik as Gateway API controller
resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = "traefik"
  create_namespace = true

  values = [
    yamlencode({
      # Enable Gateway API support
      providers = {
        kubernetesGateway = {
          enabled = true
        }
      }

      # LoadBalancer service for public access
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/ovh-loadbalancer-balance" = "roundrobin"
        }
      }

      # Enable dashboard
      ingressRoute = {
        dashboard = {
          enabled = true
        }
      }

      # Ports configuration
      ports = {
        web = {
          port = 8000
          exposedPort = 80
        }
        websecure = {
          port = 8443
          exposedPort = 443
        }
      }
    })
  ]

  wait    = true
  timeout = 600
}

# Get Traefik LoadBalancer IP
data "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }

  depends_on = [helm_release.traefik]
}

# Create Gateway for HTTP traffic
resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "vault-gateway"
      namespace = kubernetes_namespace.vault.metadata[0].name
    }
    spec = {
      gatewayClassName = "traefik"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 8000
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.traefik]
}

# Create HTTPRoute for Vault
resource "kubernetes_manifest" "vault_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "vault-route"
      namespace = kubernetes_namespace.vault.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name = kubernetes_manifest.gateway.manifest.metadata.name
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "${helm_release.vault.name}-ui"
              port = 8200
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.gateway,
    helm_release.vault
  ]
}

# Outputs
output "gateway_controller_ip" {
  value       = try(data.kubernetes_service.traefik.status[0].load_balancer[0].ingress[0].ip, "LoadBalancer IP pending...")
  description = "Gateway Controller (Traefik) public IP"
}

output "vault_gateway_url" {
  value       = "http://${try(data.kubernetes_service.traefik.status[0].load_balancer[0].ingress[0].ip, "PENDING")}"
  description = "Vault UI URL via Gateway API"
}

output "gateway_setup_info" {
  value = <<-EOT

  Gateway API Setup Complete!

  Gateway Controller: Traefik
  Public IP: ${try(data.kubernetes_service.traefik.status[0].load_balancer[0].ingress[0].ip, "PENDING")}

  Access Vault UI at:
  http://${try(data.kubernetes_service.traefik.status[0].load_balancer[0].ingress[0].ip, "PENDING")}

  Check Gateway status:
  kubectl get gateway -n vault
  kubectl get httproute -n vault
  EOT
  description = "Gateway API setup information"
}
