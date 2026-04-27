# Random suffix keeps globally-unique names (public DNS labels, Traffic Manager DNS).
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  # Regional topology: India as active primary and US as standby failover.
  regions = {
    primary = {
      location = var.primary_location
      priority = 1
    }
    secondary = {
      location = var.secondary_location
      priority = 2
    }
  }

  base_name   = "${var.project_name}-${random_string.suffix.result}"
  common_tags = merge(var.tags, { architecture = "multi-region-ha" })
}

# One resource group per region for clean blast-radius boundaries.
resource "azurerm_resource_group" "regional" {
  for_each = local.regions

  name     = "rg-${local.base_name}-${each.key}"
  location = each.value.location
  tags     = merge(local.common_tags, { region_role = each.key })
}

# Regional virtual networks isolate each site's private infrastructure.
resource "azurerm_virtual_network" "regional" {
  for_each = local.regions

  name                = "vnet-${local.base_name}-${each.key}"
  location            = azurerm_resource_group.regional[each.key].location
  resource_group_name = azurerm_resource_group.regional[each.key].name
  address_space       = [var.regional_address_spaces[each.key]]
  tags                = merge(local.common_tags, { region_role = each.key })
}

# Each region gets a dedicated application subnet.
resource "azurerm_subnet" "regional" {
  for_each = local.regions

  name                 = "snet-app-${each.key}"
  resource_group_name  = azurerm_resource_group.regional[each.key].name
  virtual_network_name = azurerm_virtual_network.regional[each.key].name
  address_prefixes     = [var.regional_subnet_prefixes[each.key]]
}

# NSG rules are intentionally minimal: HTTP for app traffic and SSH for admin break-glass.
resource "azurerm_network_security_group" "regional" {
  for_each = local.regions

  name                = "nsg-${local.base_name}-${each.key}"
  location            = azurerm_resource_group.regional[each.key].location
  resource_group_name = azurerm_resource_group.regional[each.key].name
  tags                = merge(local.common_tags, { region_role = each.key })
}

resource "azurerm_network_security_rule" "allow_http" {
  for_each = local.regions

  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.regional[each.key].name
  network_security_group_name = azurerm_network_security_group.regional[each.key].name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  for_each = local.regions

  name                        = "allow-ssh"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.regional[each.key].name
  network_security_group_name = azurerm_network_security_group.regional[each.key].name
}

resource "azurerm_subnet_network_security_group_association" "regional" {
  for_each = local.regions

  subnet_id                 = azurerm_subnet.regional[each.key].id
  network_security_group_id = azurerm_network_security_group.regional[each.key].id
}

# Public IPs back each regional load balancer and act as Traffic Manager targets.
resource "azurerm_public_ip" "regional" {
  for_each = local.regions

  name                = "pip-${local.base_name}-${each.key}"
  location            = azurerm_resource_group.regional[each.key].location
  resource_group_name = azurerm_resource_group.regional[each.key].name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.project_name}-${each.key}-${random_string.suffix.result}"
  tags                = merge(local.common_tags, { region_role = each.key })
}

# Regional L4 load balancers provide in-region redundancy across VMSS instances.
resource "azurerm_lb" "regional" {
  for_each = local.regions

  name                = "lb-${local.base_name}-${each.key}"
  location            = azurerm_resource_group.regional[each.key].location
  resource_group_name = azurerm_resource_group.regional[each.key].name
  sku                 = "Standard"
  tags                = merge(local.common_tags, { region_role = each.key })

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.regional[each.key].id
  }
}

resource "azurerm_lb_backend_address_pool" "regional" {
  for_each = local.regions

  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.regional[each.key].id
}

resource "azurerm_lb_probe" "regional" {
  for_each = local.regions

  name            = "http-probe"
  loadbalancer_id = azurerm_lb.regional[each.key].id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_rule" "http" {
  for_each = local.regions

  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.regional[each.key].id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.regional[each.key].id]
  probe_id                       = azurerm_lb_probe.regional[each.key].id
}

# VM Scale Set in each region gives instance-level HA; user-data installs Nginx for demo health endpoint.
resource "azurerm_linux_virtual_machine_scale_set" "regional" {
  for_each = local.regions

  name                = "vmss-${local.base_name}-${each.key}"
  location            = azurerm_resource_group.regional[each.key].location
  resource_group_name = azurerm_resource_group.regional[each.key].name
  sku                 = var.vm_sku
  instances           = var.vm_instances_per_region
  admin_username      = var.vm_admin_username
  health_probe_id     = azurerm_lb_probe.regional[each.key].id
  upgrade_mode        = "Automatic"

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
    username   = var.vm_admin_username
    public_key = var.ssh_public_key
  }

  # Cloud-init writes a region-specific page to make failover testing obvious.
  custom_data = base64encode(templatefile("${path.module}/scripts/cloud-init.sh", {
    region = each.value.location
    role   = each.key
  }))

  network_interface {
    name    = "nic-${each.key}"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.regional[each.key].id

      # Attach VMSS instances to the regional load balancer backend.
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.regional[each.key].id]
    }
  }

  tags = merge(local.common_tags, { region_role = each.key })
}

# Global failover entry point. Priority routing always favors India first.
resource "azurerm_traffic_manager_profile" "global" {
  name                   = "tm-${local.base_name}"
  resource_group_name    = azurerm_resource_group.regional["primary"].name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "${var.project_name}-${random_string.suffix.result}"
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }

  tags = local.common_tags
}

# Endpoint priorities enforce active/passive behavior:
# 1 => primary (India), 2 => secondary (US).
resource "azurerm_traffic_manager_external_endpoint" "regional" {
  for_each = local.regions

  name       = "tm-endpoint-${each.key}"
  profile_id = azurerm_traffic_manager_profile.global.id
  target     = azurerm_public_ip.regional[each.key].fqdn
  priority   = each.value.priority
  enabled    = true
}
