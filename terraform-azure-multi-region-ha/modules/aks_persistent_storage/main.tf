locals {
  normalized_project_name = substr(replace(var.project_name, "-", ""), 0, 10)
  region_suffix           = var.region_key == "primary" ? "pri" : "sec"
  storage_account_name = lower(
    substr(
      format(
        "stpv%s%s%s",
        local.normalized_project_name,
        local.region_suffix,
        var.unique_suffix
      ),
      0,
      24
    )
  )
}

# Creates a storage account that backs persistent volume data for AKS workloads.
resource "azurerm_storage_account" "this" {
  name                            = local.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = "StorageV2"
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  shared_access_key_enabled       = true

  # Restricts access to AKS subnet and Azure platform services.
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.subnet_id]
  }

  # Keeps object-level versioning for accidental-delete resilience.
  blob_properties {
    versioning_enabled = true
  }

  tags = merge(var.common_tags, {
    component   = "aks-persistent-storage"
    region_role = var.region_key
  })
}

# Creates the Azure Files share mounted into pods as PVC-backed storage.
resource "azurerm_storage_share" "this" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.this.name
  quota                = var.share_quota_gb
  enabled_protocol     = "SMB"
}
