terraform {
  backend "s3" {
    bucket   = "terraform-vault-project"
    key      = "vault_config/terraform.tfstate"
    region   = "eu-west-par"
    endpoint = "https://s3.eu-west-par.io.cloud.ovh.net/"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }    
  }
}

data "terraform_remote_state" "kubernetes" {
  backend = "s3"
  config = {
    bucket   = "terraform-vault-project"
    key      = "kubernetes/terraform.tfstate"  # Main kubernetes stack state file
    region   = "eu-west-par"
    endpoint = "https://s3.eu-west-par.io.cloud.ovh.net/"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}

data "terraform_remote_state" "vault_server" {
  backend = "s3"
  config = {
    bucket   = "terraform-vault-project"
    key      = "vault/terraform.tfstate"  # Main kubernetes stack state file
    region   = "eu-west-par"
    endpoint = "https://s3.eu-west-par.io.cloud.ovh.net/"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}

provider "vault" {
  address = data.terraform_remote_state.vault_server.outputs.vault_gateway_url
}
# Kubernetes provider using kubeconfig from main stack
provider "kubernetes" {
  # Alternative: Use kubeconfig content directly
  config_path = null
  host                   = yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).clusters[0].cluster.certificate-authority-data)
}
