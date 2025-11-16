

echo "Extracting kubeconfig from Terraform output..."
terraform output -raw kubeconfig > kubeconfig.yml
export KUBECONFIG="kubeconfig.yml"
