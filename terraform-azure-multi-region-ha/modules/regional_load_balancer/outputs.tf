output "public_ip_fqdn" {
  description = "Public DNS name for this regional load balancer endpoint."
  value       = azurerm_public_ip.this.fqdn
}

output "backend_pool_id" {
  description = "Backend pool ID consumed by VM Scale Set NICs."
  value       = azurerm_lb_backend_address_pool.this.id
}

output "probe_id" {
  description = "Health probe ID consumed by VM Scale Set health configuration."
  value       = azurerm_lb_probe.http.id
}
