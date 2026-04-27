# Generates short unique suffix for globally-unique names.
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
  # Region-specific compute profile keeps primary robust and secondary cost-optimized.
  regional_compute_profiles = {
    primary = {
      vm_sku             = var.primary_vm_sku
      instances          = var.primary_vm_instances
      use_spot           = false
      spot_max_bid_price = -1
    }
    secondary = {
      vm_sku             = var.secondary_vm_sku
      instances          = var.secondary_vm_instances
      use_spot           = var.enable_secondary_spot
      spot_max_bid_price = var.secondary_spot_max_bid_price
    }
  }

  # AKS region selection allows cost-aware deployments (primary-only by default).
  aks_regions = var.enable_aks ? {
    for key, region in local.regions :
    key => region if contains(var.aks_region_roles, key)
  } : {}

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

# Builds per-region foundation resources (RG, VNet, subnet, NSG, ingress rules).
module "regional_foundation" {
  for_each = local.regions

  source = "./modules/regional_foundation"

  region_key                = each.key
  base_name                 = local.base_name
  location                  = each.value.location
  address_space             = var.regional_address_spaces[each.key]
  subnet_prefix             = var.regional_subnet_prefixes[each.key]
  allowed_http_source_cidrs = var.allowed_http_source_cidrs
  enable_ssh_access         = var.enable_ssh_access
  allowed_ssh_source_cidrs  = var.allowed_ssh_source_cidrs
  common_tags               = local.common_tags
}

# Builds per-region load-balancer stack (Public IP, LB, backend pool, probe, rule).
module "regional_load_balancer" {
  for_each = local.regions

  source = "./modules/regional_load_balancer"

  region_key          = each.key
  base_name           = local.base_name
  project_name        = var.project_name
  unique_suffix       = random_string.suffix.result
  location            = module.regional_foundation[each.key].location
  resource_group_name = module.regional_foundation[each.key].resource_group_name
  common_tags         = local.common_tags
}

# Builds per-region compute layer (Linux VM Scale Set) attached to LB backend.
module "regional_compute" {
  for_each = local.regions

  source = "./modules/regional_compute"

  region_key          = each.key
  base_name           = local.base_name
  location            = module.regional_foundation[each.key].location
  resource_group_name = module.regional_foundation[each.key].resource_group_name
  subnet_id           = module.regional_foundation[each.key].subnet_id
  vm_sku              = local.regional_compute_profiles[each.key].vm_sku
  instances           = local.regional_compute_profiles[each.key].instances
  use_spot            = local.regional_compute_profiles[each.key].use_spot
  spot_max_bid_price  = local.regional_compute_profiles[each.key].spot_max_bid_price
  admin_username      = var.vm_admin_username
  ssh_public_key      = var.ssh_public_key
  health_probe_id     = module.regional_load_balancer[each.key].probe_id
  backend_pool_id     = module.regional_load_balancer[each.key].backend_pool_id
  custom_data_base64 = base64encode(templatefile("${path.module}/scripts/cloud-init.sh", {
    region = each.value.location
    role   = each.key
  }))
  common_tags = local.common_tags
}

# Builds AKS clusters in selected regions for Kubernetes workloads.
module "aks_kubernetes" {
  for_each = local.aks_regions

  source = "./modules/aks_kubernetes"

  region_key                = each.key
  base_name                 = local.base_name
  project_name              = var.project_name
  unique_suffix             = random_string.suffix.result
  location                  = module.regional_foundation[each.key].location
  resource_group_name       = module.regional_foundation[each.key].resource_group_name
  subnet_id                 = module.regional_foundation[each.key].subnet_id
  kubernetes_version        = var.aks_kubernetes_version
  private_cluster_enabled   = var.aks_private_cluster_enabled
  sku_tier                  = var.aks_sku_tier
  node_count                = var.aks_node_counts[each.key]
  node_vm_size              = var.aks_node_vm_sizes[each.key]
  enable_cluster_autoscaler = var.aks_enable_cluster_autoscaler
  node_min_count            = var.aks_node_min_counts[each.key]
  node_max_count            = var.aks_node_max_counts[each.key]
  service_cidr              = var.aks_service_cidrs[each.key]
  dns_service_ip            = var.aks_dns_service_ips[each.key]
  common_tags               = local.common_tags
}

# Builds geo-redundant DR storage and optional static fallback website.
module "dr_storage_fallback" {
  source = "./modules/dr_storage_fallback"

  storage_account_name    = local.dr_storage_account_name
  resource_group_name     = module.regional_foundation["primary"].resource_group_name
  location                = module.regional_foundation["primary"].location
  dr_data_retention_days  = var.dr_data_retention_days
  enable_fallback_website = var.enable_fallback_website
  fallback_index_html     = local.fallback_index_html
  common_tags             = local.common_tags
}

# Builds global Traffic Manager profile and wires regional/fallback endpoints.
module "global_traffic_manager" {
  source = "./modules/global_traffic_manager"

  base_name               = local.base_name
  project_name            = var.project_name
  unique_suffix           = random_string.suffix.result
  resource_group_name     = module.regional_foundation["primary"].resource_group_name
  regional_targets        = { for key, lb in module.regional_load_balancer : key => lb.public_ip_fqdn }
  endpoint_priorities     = local.endpoint_priorities
  enable_fallback_website = var.enable_fallback_website
  fallback_target         = module.dr_storage_fallback.primary_web_host
  common_tags             = local.common_tags
}
