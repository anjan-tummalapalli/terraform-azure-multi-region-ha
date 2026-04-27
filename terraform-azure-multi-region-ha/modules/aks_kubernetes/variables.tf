variable "region_key" {
  description = "Logical region role (primary/secondary)."
  type        = string
}

variable "base_name" {
  description = "Base name prefix shared across resources."
  type        = string
}

variable "project_name" {
  description = "Project name prefix used for DNS label creation."
  type        = string
}

variable "unique_suffix" {
  description = "Random suffix used for globally unique naming where required."
  type        = string
}

variable "location" {
  description = "Azure location where AKS is deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group hosting the AKS cluster."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID used by AKS node pool for Azure CNI networking."
  type        = string
}

variable "kubernetes_version" {
  description = "Optional AKS Kubernetes version. Use null to let Azure choose default supported version."
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "When true, deploys AKS as a private cluster."
  type        = bool
}

variable "sku_tier" {
  description = "AKS SKU tier (Free or Standard)."
  type        = string
}

variable "node_count" {
  description = "Desired node count for default AKS system node pool."
  type        = number

  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be at least 1."
  }
}

variable "node_vm_size" {
  description = "VM size for AKS default node pool."
  type        = string
}

variable "enable_cluster_autoscaler" {
  description = "Enables autoscaler on AKS default node pool."
  type        = bool
}

variable "node_min_count" {
  description = "Minimum node count for autoscaler."
  type        = number

  validation {
    condition     = var.enable_cluster_autoscaler ? var.node_min_count >= 1 : true
    error_message = "node_min_count must be at least 1 when autoscaler is enabled."
  }
}

variable "node_max_count" {
  description = "Maximum node count for autoscaler."
  type        = number

  validation {
    condition     = var.enable_cluster_autoscaler ? var.node_max_count >= var.node_min_count : true
    error_message = "node_max_count must be greater than or equal to node_min_count when autoscaler is enabled."
  }
}

variable "service_cidr" {
  description = "Kubernetes service CIDR for this AKS cluster."
  type        = string
}

variable "dns_service_ip" {
  description = "Kubernetes DNS service IP inside service_cidr."
  type        = string
}

variable "common_tags" {
  description = "Common tags merged into all resources."
  type        = map(string)
}
