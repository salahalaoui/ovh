# Output the Vault service details
output "vault_service_name" {
  value       = "${helm_release.vault.name}-ui"
  description = "Vault UI service name"
}

output "vault_namespace" {
  value       = kubernetes_namespace.vault.metadata[0].name
  description = "Vault namespace"
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
