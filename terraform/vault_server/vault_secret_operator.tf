resource "kubernetes_namespace" "vso" {
  metadata {
    name = "vault-secrets-operator-system"
  }
}

resource "helm_release" "vso" {
  name             = "vault-secrets-operator"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  namespace        = resource.kubernetes_namespace.vso.metadata[0].name
  create_namespace = true
  
  
  version = "1.0.1" 

    values = [
    jsonencode({
      defaultVaultConnection = {
        enabled       = true
        address       = "http://vault.vault.svc.cluster.local:8200"
        skipTLSVerify = false
      }
    })
  ]
}