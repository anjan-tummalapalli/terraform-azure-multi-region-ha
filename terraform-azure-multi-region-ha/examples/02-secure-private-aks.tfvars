project_name                = "azure-ha-demo-secure"
primary_location            = "Central India"
secondary_location          = "East US 2"
force_failover_to_secondary = false
enable_fallback_website     = true
dr_data_retention_days      = 45

primary_vm_instances         = 2
secondary_vm_instances       = 2
primary_vm_sku               = "Standard_B2s"
secondary_vm_sku             = "Standard_B2s"
enable_secondary_spot        = false
secondary_spot_max_bid_price = -1
vm_admin_username            = "azureuser"
ssh_public_key               = "REPLACE_WITH_YOUR_SSH_PUBLIC_KEY"

enable_aks                    = true
aks_region_roles              = ["primary", "secondary"]
aks_private_cluster_enabled   = true
aks_sku_tier                  = "Standard"
aks_enable_cluster_autoscaler = true
aks_node_counts               = { primary = 2, secondary = 2 }
aks_node_vm_sizes             = { primary = "Standard_B2s", secondary = "Standard_B2s" }
aks_node_min_counts           = { primary = 2, secondary = 2 }
aks_node_max_counts           = { primary = 5, secondary = 5 }
aks_service_cidrs             = { primary = "10.130.0.0/16", secondary = "10.140.0.0/16" }
aks_dns_service_ips           = { primary = "10.130.0.10", secondary = "10.140.0.10" }

allowed_http_source_cidrs = ["203.0.113.0/24"]
enable_ssh_access         = false
allowed_ssh_source_cidrs  = []

tags = {
  environment = "production"
  owner       = "security-team"
  profile     = "secure-private-aks"
}
