# Reserves a static public IP used by the regional load balancer.
resource "azurerm_public_ip" "this" {
  name                = "pip-${var.base_name}-${var.region_key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label = (
    "${var.project_name}-${var.region_key}-${var.unique_suffix}"
  )
  tags = merge(var.common_tags, { region_role = var.region_key })
}

# Creates a regional public load balancer for instance-level HA.
resource "azurerm_lb" "this" {
  name                = "lb-${var.base_name}-${var.region_key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = merge(var.common_tags, { region_role = var.region_key })

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

# Creates backend pool that VMSS instances join.
resource "azurerm_lb_backend_address_pool" "this" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.this.id
}

# Defines HTTP probe used to determine backend health.
resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.this.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# Exposes HTTP rule to forward client traffic to healthy instances.
resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.http.id
}
