# Creates a dedicated resource group for this region to isolate blast radius.
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.base_name}-${var.region_key}"
  location = var.location
  tags     = merge(var.common_tags, { region_role = var.region_key })
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

# Allows HTTP ingress for application traffic and health probing.
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

# Allows SSH ingress for controlled administrative access.
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow-ssh"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

# Binds NSG policies to the app subnet.
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.this.id
}
