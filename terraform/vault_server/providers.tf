terraform {
  backend "s3" {
    bucket   = "terraform-vault-project"
    key      = "vault/terraform.tfstate"
    region   = "eu-west-par"
    endpoint = "https://s3.eu-west-par.io.cloud.ovh.net/"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}
terraform {
required_version    = ">= 0.14.0" # Takes into account Terraform versions from 0.14.0
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.4"
    }
    ovh = {
      source  = "ovh/ovh"
      version = ">= 0.13.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}


provider "ovh" {
  alias = "ovh"
  endpoint = "ovh-eu" # ovh-eu - for OVHcloud europe API / ovh-us - for OVHcloud USA API  / ovh-ca - for OVHcloud North-Ameria API https://docs.ovh.com/sg/en/kubernetes/creating-a-cluster-through-terraform/
}

provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3/" # Authentication URL
  domain_name = "default" # Domain name - Always at 'default' for OVHcloud
  region      = "GRA9"
  tenant_id   = "725c08f4e5e04dfa8bbbadcada2c0638" # Your project ID

}

# Data source to get kubeconfig from the main kubernetes stack
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

# Kubernetes provider using kubeconfig from main stack
provider "kubernetes" {
  # Alternative: Use kubeconfig content directly
  config_path = null
  host                   = yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).clusters[0].cluster.certificate-authority-data)
}

# Helm provider using same kubeconfig
provider "helm" {
  kubernetes = {
    config_path = null
    host                   = yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).clusters[0].cluster.server
    client_certificate     = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(data.terraform_remote_state.kubernetes.outputs.kubeconfig).clusters[0].cluster.certificate-authority-data)
    # Alternative: Use same credentials as kubernetes provider above
  }
}
