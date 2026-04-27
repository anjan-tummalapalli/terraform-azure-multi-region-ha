output "resource_group_name" {
  description = "Resource group name created for this region."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure location for this regional foundation."
  value       = azurerm_resource_group.this.location
}

output "subnet_id" {
  description = "Application subnet ID used by compute resources."
  value       = azurerm_subnet.app.id
}
