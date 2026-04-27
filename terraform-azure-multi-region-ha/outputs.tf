output "traffic_manager_fqdn" {
  description = "Global DNS name clients should use (automatic failover managed by Traffic Manager)."
  value       = module.global_traffic_manager.traffic_manager_fqdn
}

output "traffic_manager_endpoint_priorities" {
  description = "Effective Traffic Manager endpoint priorities after optional forced failover toggle."
  value       = local.endpoint_priorities
}

output "regional_public_fqdns" {
  description = "Regional load balancer DNS endpoints used by Traffic Manager."
  value = {
    for key, lb in module.regional_load_balancer :
    key => lb.public_ip_fqdn
  }
}

output "regional_resource_groups" {
  description = "Resource groups created for each region role."
  value = {
    for key, foundation in module.regional_foundation :
    key => foundation.resource_group_name
  }
}

output "regional_vmss_names" {
  description = "VM Scale Set names for each region role."
  value = {
    for key, compute in module.regional_compute :
    key => compute.vmss_name
  }
}

output "dr_storage_account_name" {
  description = "Geo-redundant storage account used for DR artifacts and fallback static site."
  value       = module.dr_storage_fallback.storage_account_name
}

output "dr_backup_container_name" {
  description = "Private blob container intended for DR backup artifacts."
  value       = module.dr_storage_fallback.dr_backup_container_name
}

output "fallback_website_url" {
  description = "Fallback maintenance URL used as final Traffic Manager endpoint."
  value       = var.enable_fallback_website ? "https://${module.dr_storage_fallback.primary_web_host}" : null
}
