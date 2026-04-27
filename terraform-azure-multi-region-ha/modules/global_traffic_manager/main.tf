# Creates global DNS entry point used by clients for multi-region routing.
resource "azurerm_traffic_manager_profile" "this" {
  name                   = "tm-${var.base_name}"
  resource_group_name    = var.resource_group_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "${var.project_name}-${var.unique_suffix}"
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

  tags = var.common_tags
}

# Registers regional endpoints (India and US) with explicit failover priorities.
resource "azurerm_traffic_manager_external_endpoint" "regional" {
  for_each = var.regional_targets

  name       = "tm-endpoint-${each.key}"
  profile_id = azurerm_traffic_manager_profile.this.id
  target     = each.value
  priority   = var.endpoint_priorities[each.key]
  enabled    = true
}

# Registers last-resort fallback endpoint for full regional outage scenarios.
resource "azurerm_traffic_manager_external_endpoint" "fallback" {
  count = var.enable_fallback_website ? 1 : 0

  name       = "tm-endpoint-fallback"
  profile_id = azurerm_traffic_manager_profile.this.id
  target     = var.fallback_target
  priority   = var.endpoint_priorities["fallback"]
  enabled    = true
}
