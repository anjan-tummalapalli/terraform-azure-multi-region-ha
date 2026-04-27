output "traffic_manager_fqdn" {
  description = "Global DNS name clients should use for automatic failover routing."
  value       = azurerm_traffic_manager_profile.this.fqdn
}
