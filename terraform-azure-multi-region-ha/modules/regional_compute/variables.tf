variable "region_key" {
  description = "Logical region role (primary/secondary)."
  type        = string
}

variable "base_name" {
  description = "Base name prefix shared across resources."
  type        = string
}

variable "location" {
  description = "Azure location where the VM Scale Set is deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that hosts the VM Scale Set."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where VM Scale Set instances attach."
  type        = string
}

variable "vm_sku" {
  description = "Azure VM size for Scale Set instances."
  type        = string
}

variable "instances" {
  description = "Desired instance count for this region."
  type        = number
}

variable "admin_username" {
  description = "Admin username for VM instances."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key used for VM admin access."
  type        = string
}

variable "health_probe_id" {
  description = "Load balancer probe ID used by VM Scale Set health checks."
  type        = string
}

variable "backend_pool_id" {
  description = "Load balancer backend pool ID to register VM instances."
  type        = string
}

variable "custom_data_base64" {
  description = "Base64-encoded cloud-init payload for VM bootstrap."
  type        = string
}

variable "common_tags" {
  description = "Common tags merged into all resources."
  type        = map(string)
}
