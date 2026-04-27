variable "project_name" {
  description = "Short lowercase project prefix used in Azure resource names."
  type        = string
  default     = "azure-ha-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "project_name must be 3-20 chars and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "primary_location" {
  description = "Primary Azure region (India)."
  type        = string
  default     = "Central India"
}

variable "secondary_location" {
  description = "Secondary Azure region (US failover)."
  type        = string
  default     = "East US 2"
}

variable "force_failover_to_secondary" {
  description = "When true, swaps Traffic Manager priorities so the US region becomes active."
  type        = bool
  default     = false
}

variable "enable_fallback_website" {
  description = "When true, enables a static maintenance website as last-resort fallback endpoint."
  type        = bool
  default     = true
}

variable "dr_data_retention_days" {
  description = "Retention period (days) for DR artifacts in geo-redundant storage."
  type        = number
  default     = 30

  validation {
    condition     = var.dr_data_retention_days >= 7 && var.dr_data_retention_days <= 365
    error_message = "dr_data_retention_days must be between 7 and 365."
  }
}

variable "regional_address_spaces" {
  description = "VNet CIDRs by region key (primary/secondary)."
  type        = map(string)
  default = {
    primary   = "10.10.0.0/16"
    secondary = "10.20.0.0/16"
  }
}

variable "regional_subnet_prefixes" {
  description = "Subnet CIDRs by region key (primary/secondary)."
  type        = map(string)
  default = {
    primary   = "10.10.1.0/24"
    secondary = "10.20.1.0/24"
  }
}

variable "vm_instances_per_region" {
  description = "Deprecated global instance count. Prefer primary_vm_instances/secondary_vm_instances."
  type        = number
  default     = 2
}

variable "vm_sku" {
  description = "Deprecated global VM SKU. Prefer primary_vm_sku/secondary_vm_sku."
  type        = string
  default     = "Standard_B2s"
}

variable "primary_vm_instances" {
  description = "Cost-aware primary region instance count (India)."
  type        = number
  default     = 2

  validation {
    condition     = var.primary_vm_instances >= 1
    error_message = "primary_vm_instances must be at least 1."
  }
}

variable "secondary_vm_instances" {
  description = "Cost-aware secondary region standby instance count (US)."
  type        = number
  default     = 1

  validation {
    condition     = var.secondary_vm_instances >= 1
    error_message = "secondary_vm_instances must be at least 1."
  }
}

variable "primary_vm_sku" {
  description = "Primary region VM SKU."
  type        = string
  default     = "Standard_B2s"
}

variable "secondary_vm_sku" {
  description = "Secondary region VM SKU tuned for lower standby cost."
  type        = string
  default     = "Standard_B1ms"
}

variable "enable_secondary_spot" {
  description = "When true, secondary region VMSS uses Spot instances for lower standby cost."
  type        = bool
  default     = true
}

variable "secondary_spot_max_bid_price" {
  description = "Spot bid price for secondary VMSS (-1 means pay up to on-demand price cap)."
  type        = number
  default     = -1
}

variable "vm_admin_username" {
  description = "Admin username for VM Scale Set instances."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key used for Linux VM Scale Set access."
  type        = string
}

variable "tags" {
  description = "Optional tags to apply to all resources."
  type        = map(string)
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
