terraform {
  backend "s3" {
    bucket   = "terraform-vault-project"
    key      = "kubernetes/terraform.tfstate"
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
  # You need to set these via environment variables:
  # export OS_USERNAME="your-openstack-username"
  # export OS_PASSWORD="your-openstack-password"
}
