variable "region_key" {
  description = "Logical region role (primary/secondary)."
  type        = string
}

variable "base_name" {
  description = "Base name prefix shared across resources."
  type        = string
}

variable "location" {
  description = "Azure region location for this module instance."
  type        = string
}

variable "address_space" {
  description = "CIDR address space for the regional virtual network."
  type        = string
}

variable "subnet_prefix" {
  description = "CIDR prefix for the application subnet in this region."
  type        = string
}

variable "allowed_http_source_cidrs" {
  description = "Source CIDRs allowed to reach HTTP application endpoint."
  type        = list(string)
}

variable "enable_ssh_access" {
  description = "When true, creates SSH NSG rule(s) for break-glass access."
  type        = bool
}

variable "allowed_ssh_source_cidrs" {
  description = "Source CIDRs allowed for SSH when enable_ssh_access is enabled."
  type        = list(string)

  validation {
    condition     = var.enable_ssh_access ? length(var.allowed_ssh_source_cidrs) > 0 : true
    error_message = "allowed_ssh_source_cidrs must contain at least one CIDR when enable_ssh_access is true."
  }
}

variable "common_tags" {
  description = "Common tags merged into all resources."
  type        = map(string)
}
