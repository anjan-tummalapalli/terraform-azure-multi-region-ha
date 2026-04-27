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
  description = "Number of VM Scale Set instances per region for zonal resiliency."
  type        = number
  default     = 2
}

variable "vm_sku" {
  description = "VM size for the Linux VM Scale Set in each region."
  type        = string
  default     = "Standard_B2s"
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
