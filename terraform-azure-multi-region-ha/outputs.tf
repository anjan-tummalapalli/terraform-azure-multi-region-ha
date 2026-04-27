output "traffic_manager_fqdn" {
  description = "Global DNS name clients should use (automatic failover managed by Traffic Manager)."
  value       = azurerm_traffic_manager_profile.global.fqdn
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
