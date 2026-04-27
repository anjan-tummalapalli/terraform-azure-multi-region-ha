# Creates a managed AKS cluster for container workloads in the selected region.
resource "azurerm_kubernetes_cluster" "this" {
  name                    = "aks-${var.base_name}-${var.region_key}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = "${var.project_name}-${var.region_key}-${var.unique_suffix}"
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.private_cluster_enabled
  sku_tier                = var.sku_tier

  # Enables policy and workload identity integrations for stronger security posture.
  azure_policy_enabled      = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Uses a system node pool with optional autoscaling and explicit subnet placement.
  default_node_pool {
    name                = "system"
    vm_size             = var.node_vm_size
    node_count          = var.node_count
    enable_auto_scaling = var.enable_cluster_autoscaler
    min_count           = var.enable_cluster_autoscaler ? var.node_min_count : null
    max_count           = var.enable_cluster_autoscaler ? var.node_max_count : null
    vnet_subnet_id      = var.subnet_id
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    max_pods            = 30
  }

  # Uses managed identity so cluster components can authenticate without static secrets.
  identity {
    type = "SystemAssigned"
  }

  # Azure CNI networking integrates pod and service networking with the VNet.
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  tags = merge(var.common_tags, {
    region_role = var.region_key
    component   = "aks"
  })
}
