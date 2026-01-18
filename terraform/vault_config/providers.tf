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
  }
}


provider "vault" {
  address = "http://51.75.185.94:8200"
}
