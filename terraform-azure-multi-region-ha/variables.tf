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

variable "enable_aks" {
  description = "When true, deploys AKS clusters in selected region roles."
  type        = bool
  default     = true
}

variable "aks_region_roles" {
  description = "Region roles where AKS should be deployed."
  type        = list(string)
  default     = ["primary"]

  validation {
    condition     = alltrue([for role in var.aks_region_roles : contains(["primary", "secondary"], role)])
    error_message = "aks_region_roles can only contain 'primary' and/or 'secondary'."
  }
}

variable "aks_kubernetes_version" {
  description = "Optional AKS Kubernetes version. Set null to use Azure default latest supported version."
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
    secondary = 1
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
    primary   = 1
    secondary = 1
  }
}

variable "aks_node_max_counts" {
  description = "AKS node pool autoscaler maximum node count per region role."
  type        = map(number)
  default = {
    primary   = 4
    secondary = 2
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
  description = "AKS DNS service IP per region role. Must be inside corresponding aks_service_cidrs."
  type        = map(string)
  default = {
    primary   = "10.110.0.10"
    secondary = "10.120.0.10"
  }
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

variable "allowed_http_source_cidrs" {
  description = "Source CIDRs allowed to reach application HTTP endpoint."
  type        = list(string)
  default     = ["*"]
}

variable "enable_ssh_access" {
  description = "When true, creates SSH NSG rule(s) for controlled break-glass access."
  type        = bool
  default     = false
}

variable "allowed_ssh_source_cidrs" {
  description = "Source CIDRs allowed for SSH when enable_ssh_access is true."
  type        = list(string)
  default     = []

  validation {
    condition     = var.enable_ssh_access ? length(var.allowed_ssh_source_cidrs) > 0 : true
    error_message = "Provide at least one allowed_ssh_source_cidrs entry when enable_ssh_access is true."
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
