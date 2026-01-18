# Output the Vault service details
output "vault_service_name" {
  value       = "${helm_release.vault.name}-ui"
  description = "Vault UI service name"
}

output "vault_namespace" {
  value       = kubernetes_namespace.vault.metadata[0].name
  description = "Vault namespace"
}

output "vault_lb_ip" {
  value       = try(kubernetes_service.vault_lb.status[0].load_balancer[0].ingress[0].ip, "Provisioning in OVH...")
  description = "The public IP of the Vault Load Balancer"
}
