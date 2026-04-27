# Creates a dedicated resource group for this region to isolate blast radius.
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.base_name}-${var.region_key}"
  location = var.location
  tags     = merge(var.common_tags, { region_role = var.region_key })
}

locals {
  # Indexed maps allow deterministic NSG rule priorities from ordered CIDR lists.
  http_source_map = {
    for index, cidr in var.allowed_http_source_cidrs :
    index => cidr
  }

  ssh_source_map = var.enable_ssh_access ? {
    for index, cidr in var.allowed_ssh_source_cidrs :
    index => cidr
  } : {}
}

# Provisions the regional virtual network for private networking boundaries.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.base_name}-${var.region_key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.address_space]
  tags                = merge(var.common_tags, { region_role = var.region_key })
}

# Creates the application subnet consumed by VM Scale Set instances.
resource "azurerm_subnet" "app" {
  name                 = "snet-app-${var.region_key}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefix]
}

# Defines regional network security controls.
resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.base_name}-${var.region_key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = merge(var.common_tags, { region_role = var.region_key })
}

# Allows HTTP ingress only from explicit source CIDRs.
resource "azurerm_network_security_rule" "allow_http" {
  for_each = local.http_source_map

  name                        = "allow-http"
  priority                    = 100 + each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = each.value
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

# Allows SSH ingress only when explicitly enabled for break-glass support.
resource "azurerm_network_security_rule" "allow_ssh" {
  for_each = local.ssh_source_map

  name                        = "allow-ssh-${each.key}"
  priority                    = 200 + each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = each.value
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

# Binds NSG policies to the app subnet.
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.this.id
}
