output "storage_account_name" {
  description = "Storage account name used by AKS persistent volumes."
  value       = azurerm_storage_account.this.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account for AKS persistent volumes."
  value       = azurerm_storage_account.this.id
}

output "storage_share_name" {
  description = "Azure Files share name used by AKS persistent volumes."
  value       = azurerm_storage_share.this.name
}

output "resource_group_name" {
  description = "Resource group name containing persistent storage resources."
  value       = var.resource_group_name
}

output "kubernetes_secret_name" {
  description = "Recommended Kubernetes secret name for Azure Files auth."
  value       = "azurefile-secret-${var.region_key}"
}
