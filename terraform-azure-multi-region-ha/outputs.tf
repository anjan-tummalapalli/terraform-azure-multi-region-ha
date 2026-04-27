output "traffic_manager_fqdn" {
  description = "Global DNS name clients should use (automatic failover managed by Traffic Manager)."
  value       = azurerm_traffic_manager_profile.global.fqdn
}

output "traffic_manager_endpoint_priorities" {
  description = "Effective Traffic Manager endpoint priorities after optional forced failover toggle."
  value       = local.endpoint_priorities
}

output "regional_public_fqdns" {
  description = "Regional load balancer DNS endpoints used by Traffic Manager."
  value = {
    for k, v in azurerm_public_ip.regional :
    k => v.fqdn
  }
}

output "regional_resource_groups" {
  description = "Resource groups created for each region role."
  value = {
    for k, v in azurerm_resource_group.regional :
    k => v.name
  }
}

output "regional_vmss_names" {
  description = "VM Scale Set names for each region role."
  value = {
    for k, v in azurerm_linux_virtual_machine_scale_set.regional :
    k => v.name
  }
}

output "dr_storage_account_name" {
  description = "Geo-redundant storage account used for DR artifacts and fallback static site."
  value       = azurerm_storage_account.dr.name
}

output "dr_backup_container_name" {
  description = "Private blob container intended for DR backup artifacts."
  value       = azurerm_storage_container.dr_backups.name
}

output "fallback_website_url" {
  description = "Fallback maintenance URL used as final Traffic Manager endpoint."
  value       = var.enable_fallback_website ? "https://${azurerm_storage_account.dr.primary_web_host}" : null
}
