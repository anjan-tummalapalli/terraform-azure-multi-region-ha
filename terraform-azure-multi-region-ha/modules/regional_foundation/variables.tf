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

variable "common_tags" {
  description = "Common tags merged into all resources."
  type        = map(string)
}
