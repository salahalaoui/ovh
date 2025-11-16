
locals {
  region = "GRA9"
  service_name = "725c08f4e5e04dfa8bbbadcada2c0638"
}
resource "ovh_cloud_project_network_private" "this" {
   service_name = "725c08f4e5e04dfa8bbbadcada2c0638"
   name         = "vpc" # Network name
   regions      = ["GRA9"]
   vlan_id      = 1900 # VLAN ID for vRack
}

# Subnet for the private network
resource "ovh_cloud_project_network_private_subnet" "this" {
   service_name = ovh_cloud_project_network_private.this.service_name
   network_id   = ovh_cloud_project_network_private.this.id
   region       = "GRA9"
   start        = "10.1.0.2"
   end          = "10.1.255.254"
   network      = "10.1.0.0/16"
   dhcp         = true
   no_gateway   = false
}

# Gateway for the private network
resource "ovh_cloud_project_gateway" "this" {
   service_name = ovh_cloud_project_network_private.this.service_name
   name         = "gateway-gra9-1511-zgauI"
   model        = "s"
   region       = "GRA9"
   network_id   = ovh_cloud_project_network_private.this.regions_openstack_ids["GRA9"]
   subnet_id    = ovh_cloud_project_network_private_subnet.this.id
}

# SSH keypair - OpenStack provider required
# To create this, you need OpenStack credentials (see providers.tf)
# Alternative: Create manually via ovhcloud CLI or OVH UI
resource "openstack_compute_keypair_v2" "this" {
  name       = "bastion_keypair"
  region     = local.region
  public_key = file("demo.pub")
}

# Kubernetes cluster linked to the private network
resource "ovh_cloud_project_kube" "this" {
     service_name = local.service_name
     name = "cluster"
     region = local.region
     version = "1.34"
     private_network_id = ovh_cloud_project_network_private.this.regions_openstack_ids[local.region]

     private_network_configuration {
         default_vrack_gateway              = ""
         private_network_routing_as_default = true
     }
}

# Node pool for Kubernetes cluster
# Using b2-7: 2 vCPU, 7GB RAM (cheapest general-purpose option)
resource "ovh_cloud_project_kube_nodepool" "this" {
  service_name  = local.service_name
  kube_id       = ovh_cloud_project_kube.this.id
  name          = "node-pool-1"
  flavor_name   = "b3-8"        # 2 vCPU, 7GB RAM (~€24/month per node)
  desired_nodes = 1
  max_nodes     = 2
  min_nodes     = 1
}
