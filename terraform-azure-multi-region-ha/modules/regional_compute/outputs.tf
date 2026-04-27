output "vmss_name" {
  description = "Name of the VM Scale Set created for this region."
  value       = azurerm_linux_virtual_machine_scale_set.this.name
}
