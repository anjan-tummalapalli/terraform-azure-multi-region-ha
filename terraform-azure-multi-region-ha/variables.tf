variable "project_name" {
  description = "Short lowercase project prefix used in Azure resource names."
  type        = string
  default     = "azure-ha-demo"

  validation {
    condition = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = (
      "project_name must be 3-20 chars with lowercase letters, nums, hyphens."
    )
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

variable "enable_aks" {
  description = "When true, deploys AKS clusters in selected region roles."
  type        = bool
  default     = true
}

variable "aks_region_roles" {
  description = "Region roles where AKS should be deployed."
  type        = list(string)
  default     = ["primary", "secondary"]

  validation {
    condition = alltrue([
      for role in var.aks_region_roles :
      contains(["primary", "secondary"], role)
    ])
    error_message = "aks_region_roles may include only primary and secondary."
  }
}

variable "aks_kubernetes_version" {
  description = "Optional AKS version. Null uses Azure default version."
  type        = string
  default     = null
}

variable "aks_private_cluster_enabled" {
  description = "When true, deploys AKS private clusters."
  type        = bool
  default     = false
}

variable "aks_sku_tier" {
  description = "AKS control plane SKU tier (Free or Standard)."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.aks_sku_tier)
    error_message = "aks_sku_tier must be either 'Free' or 'Standard'."
  }
}

variable "aks_node_counts" {
  description = "AKS node count per region role."
  type        = map(number)
  default = {
    primary   = 2
    secondary = 2
  }
}

variable "aks_node_vm_sizes" {
  description = "AKS node VM size per region role."
  type        = map(string)
  default = {
    primary   = "Standard_B2s"
    secondary = "Standard_B2s"
  }
}

variable "aks_enable_cluster_autoscaler" {
  description = "Enables AKS node pool autoscaler."
  type        = bool
  default     = true
}

variable "aks_node_min_counts" {
  description = "AKS node pool autoscaler minimum node count per region role."
  type        = map(number)
  default = {
    primary   = 2
    secondary = 2
  }
}

variable "aks_node_max_counts" {
  description = "AKS node pool autoscaler maximum node count per region role."
  type        = map(number)
  default = {
    primary   = 4
    secondary = 4
  }
}

variable "aks_service_cidrs" {
  description = "AKS service CIDR per region role."
  type        = map(string)
  default = {
    primary   = "10.110.0.0/16"
    secondary = "10.120.0.0/16"
  }
}

variable "aks_dns_service_ips" {
  description = "AKS DNS service IP per role within matching service CIDR."
  type        = map(string)
  default = {
    primary   = "10.110.0.10"
    secondary = "10.120.0.10"
  }
}

variable "enable_aks_persistent_storage" {
  description = "When true, creates Azure Files for AKS persistent volumes."
  type        = bool
  default     = true
}

variable "aks_persistent_storage_account_tier" {
  description = "Performance tier for AKS persistent storage accounts."
  type        = string
  default     = "Standard"

  validation {
    condition = contains(
      ["Standard", "Premium"],
      var.aks_persistent_storage_account_tier
    )
    error_message = (
      "aks_persistent_storage_account_tier must be Standard/Premium."
    )
  }
}

variable "aks_persistent_storage_replication_type" {
  description = "Redundancy model for AKS persistent storage accounts."
  type        = string
  default     = "LRS"

  validation {
    condition = contains(
      ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"],
      var.aks_persistent_storage_replication_type
    )
    error_message = "aks_persistent_storage_replication_type is invalid."
  }
}

variable "aks_persistent_file_share_name" {
  description = "Azure Files share name mounted by AKS workloads."
  type        = string
  default     = "app-content"

  validation {
    condition = can(
      regex("^[a-z0-9-]{3,63}$", var.aks_persistent_file_share_name)
    )
    error_message = (
      "aks_persistent_file_share_name must be 3-63 lowercase chars."
    )
  }
}

variable "aks_persistent_share_quota_gb" {
  description = "Azure Files share quota in GiB used for AKS persistent data."
  type        = number
  default     = 32

  validation {
    condition = (
      var.aks_persistent_share_quota_gb >= 5 &&
      var.aks_persistent_share_quota_gb <= 5120
    )
    error_message = "aks_persistent_share_quota_gb must be between 5 and 5120."
  }
}

variable "force_failover_to_secondary" {
  description = "When true, US becomes active by swapping TM priorities."
  type        = bool
  default     = false
}

variable "enable_fallback_website" {
  description = "When true, enables static maintenance as last-resort fallback."
  type        = bool
  default     = true
}

variable "dr_data_retention_days" {
  description = "Retention days for DR artifacts in geo-redundant storage."
  type        = number
  default     = 30

  validation {
    condition = (
      var.dr_data_retention_days >= 7 &&
      var.dr_data_retention_days <= 365
    )
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
  description = "Deprecated global instance count. Prefer per-region vars."
  type        = number
  default     = 2
}

variable "vm_sku" {
  description = "Deprecated global VM SKU. Prefer per-region VM SKU vars."
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
  description = "Cost-aware secondary region baseline instance count (US)."
  type        = number
  default     = 2

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
  description = "Secondary region VM SKU tuned for resilience and cost."
  type        = string
  default     = "Standard_B2s"
}

variable "enable_secondary_spot" {
  description = "When true, secondary VMSS uses Spot for optional savings."
  type        = bool
  default     = false
}

variable "secondary_spot_max_bid_price" {
  description = "Spot bid for secondary VMSS (-1 means on-demand price cap)."
  type        = number
  default     = -1
}

variable "allowed_http_source_cidrs" {
  description = "Source CIDRs allowed to reach application HTTP endpoint."
  type        = list(string)
  default     = ["*"]
}

variable "enable_ssh_access" {
  description = "When true, creates SSH NSG rule(s) for break-glass access."
  type        = bool
  default     = false
}

variable "allowed_ssh_source_cidrs" {
  description = "Source CIDRs allowed for SSH when enable_ssh_access is true."
  type        = list(string)
  default     = []

  validation {
    condition = (
      var.enable_ssh_access ? length(var.allowed_ssh_source_cidrs) > 0 : true
    )
    error_message = (
      "Provide at least one allowed_ssh_source_cidrs entry when enabled."
    )
  }
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
