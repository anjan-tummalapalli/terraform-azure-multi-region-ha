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
    }
    secondary = {
      location = var.secondary_location
    }
  }

  # Allows controlled failover/failback during DR drills or incidents.
  endpoint_priorities = var.force_failover_to_secondary ? {
    primary   = 2
    secondary = 1
    fallback  = 3
    } : {
    primary   = 1
    secondary = 2
    fallback  = 3
  }

  base_name               = "${var.project_name}-${random_string.suffix.result}"
  dr_storage_account_name = substr("st${replace(var.project_name, "-", "")}${random_string.suffix.result}", 0, 24)
  common_tags             = merge(var.tags, { architecture = "multi-region-ha" })

  fallback_index_html = <<-HTML
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Service Recovery In Progress</title>
      </head>
      <body style="font-family: Arial, sans-serif; margin: 2rem;">
        <h1>Service Recovery In Progress</h1>
        <p>This is the emergency fallback endpoint for <strong>${var.project_name}</strong>.</p>
        <p>Primary and secondary regional endpoints are currently unavailable.</p>
        <p>Please retry shortly.</p>
      </body>
    </html>
  HTML
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

# DR storage stores runbooks/backups/artifacts in geo-redundant storage and hosts the fallback site.
resource "azurerm_storage_account" "dr" {
  name                            = local.dr_storage_account_name
  resource_group_name             = azurerm_resource_group.regional["primary"].name
  location                        = azurerm_resource_group.regional["primary"].location
  account_tier                    = "Standard"
  account_replication_type        = "RAGRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.dr_data_retention_days
    }

    container_delete_retention_policy {
      days = var.dr_data_retention_days
    }
  }

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = merge(local.common_tags, { component = "dr-fallback" })
}

# Private container for DR backup artifacts (DB dumps, export bundles, runbook payloads, etc.).
resource "azurerm_storage_container" "dr_backups" {
  name                  = "dr-backups"
  storage_account_name  = azurerm_storage_account.dr.name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "dr_retention" {
  storage_account_id = azurerm_storage_account.dr.id

  rule {
    name    = "expire-dr-backups"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["dr-backups/"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.dr_data_retention_days
      }
    }
  }
}

# Upload static fallback pages served only when both regional endpoints are unavailable.
resource "azurerm_storage_blob" "fallback_index" {
  count = var.enable_fallback_website ? 1 : 0

  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.dr.name
  storage_container_name = "$web"
  type                   = "Block"
  source_content         = local.fallback_index_html
  content_type           = "text/html"

  depends_on = [azurerm_storage_account.dr]
}

resource "azurerm_storage_blob" "fallback_404" {
  count = var.enable_fallback_website ? 1 : 0

  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.dr.name
  storage_container_name = "$web"
  type                   = "Block"
  source_content         = local.fallback_index_html
  content_type           = "text/html"

  depends_on = [azurerm_storage_account.dr]
}

# Global failover entry point.
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

# Regional endpoints are automatically ordered based on failover toggle.
resource "azurerm_traffic_manager_external_endpoint" "regional" {
  for_each = local.regions

  name       = "tm-endpoint-${each.key}"
  profile_id = azurerm_traffic_manager_profile.global.id
  target     = azurerm_public_ip.regional[each.key].fqdn
  priority   = local.endpoint_priorities[each.key]
  enabled    = true
}

# Last-resort fallback endpoint serves a maintenance page if both regions fail.
resource "azurerm_traffic_manager_external_endpoint" "fallback" {
  count = var.enable_fallback_website ? 1 : 0

  name       = "tm-endpoint-fallback"
  profile_id = azurerm_traffic_manager_profile.global.id
  target     = azurerm_storage_account.dr.primary_web_host
  priority   = local.endpoint_priorities["fallback"]
  enabled    = true

  depends_on = [azurerm_storage_blob.fallback_index]
}
