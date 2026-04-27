# Deploys Linux VM Scale Set instances for regional application capacity.
resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "vmss-${var.base_name}-${var.region_key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.vm_sku
  instances           = var.instances
  admin_username      = var.admin_username
  health_probe_id     = var.health_probe_id
  upgrade_mode        = "Automatic"
  # Avoids temporary extra instances created during provisioning.
  overprovision = false
  # Spot is applied only where explicitly requested (typically standby region).
  priority = var.use_spot ? "Spot" : "Regular"
  # Spot eviction behavior keeps evicted nodes deallocated for low-cost standby.
  eviction_policy = var.use_spot ? "Deallocate" : null
  # Bid cap for Spot instances; -1 means up to on-demand price.
  max_bid_price = var.use_spot ? var.spot_max_bid_price : null

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  custom_data = var.custom_data_base64

  network_interface {
    name    = "nic-${var.region_key}"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id

      load_balancer_backend_address_pool_ids = [var.backend_pool_id]
    }
  }

  tags = merge(var.common_tags, { region_role = var.region_key })
}
