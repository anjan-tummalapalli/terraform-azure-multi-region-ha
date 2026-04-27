output "storage_account_name" {
  description = "Storage account name used for DR and fallback assets."
  value       = azurerm_storage_account.this.name
}

output "primary_web_host" {
  description = "Static website hostname used as fallback endpoint target."
  value       = azurerm_storage_account.this.primary_web_host
}

output "dr_backup_container_name" {
  description = "Private container name storing DR backup artifacts."
  value       = azurerm_storage_container.dr_backups.name
}
