# Creates geo-redundant storage used for DR artifacts and fallback website hosting.
resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
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

  tags = merge(var.common_tags, { component = "dr-fallback" })
}

# Creates private container for DR backup payloads (dumps, exports, runbooks).
resource "azurerm_storage_container" "dr_backups" {
  name                  = "dr-backups"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Applies lifecycle cleanup policy to avoid unlimited DR backup growth.
resource "azurerm_storage_management_policy" "dr_retention" {
  storage_account_id = azurerm_storage_account.this.id

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

# Uploads primary fallback page served during full regional outage.
resource "azurerm_storage_blob" "fallback_index" {
  count = var.enable_fallback_website ? 1 : 0

  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  source_content         = var.fallback_index_html
  content_type           = "text/html"

  depends_on = [azurerm_storage_account.this]
}

# Uploads 404 page aligned with fallback maintenance content.
resource "azurerm_storage_blob" "fallback_404" {
  count = var.enable_fallback_website ? 1 : 0

  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  source_content         = var.fallback_index_html
  content_type           = "text/html"

  depends_on = [azurerm_storage_account.this]
}
