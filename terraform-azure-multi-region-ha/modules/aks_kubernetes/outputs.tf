output "cluster_name" {
  description = "AKS cluster name for this region role."
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_admin_config_command" {
  description = "CLI helper command to fetch kubeconfig credentials for this cluster."
  value       = "az aks get-credentials --resource-group ${azurerm_kubernetes_cluster.this.resource_group_name} --name ${azurerm_kubernetes_cluster.this.name} --overwrite-existing"
}

output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}
