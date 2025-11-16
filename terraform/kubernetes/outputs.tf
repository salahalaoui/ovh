output "kubeconfig" {
 value = ovh_cloud_project_kube.this.kubeconfig
 sensitive = true
}