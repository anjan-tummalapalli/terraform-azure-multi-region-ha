variable "region_key" {
  description = "Logical region role (primary/secondary)."
  type        = string
}

variable "base_name" {
  description = "Base name prefix shared across resources."
  type        = string
}

variable "project_name" {
  description = "Project prefix used for DNS label generation."
  type        = string
}

variable "unique_suffix" {
  description = "Random suffix used to ensure DNS uniqueness."
  type        = string
}

variable "location" {
  description = "Azure location where LB resources are deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that hosts the load balancer stack."
  type        = string
}

variable "common_tags" {
  description = "Common tags merged into all resources."
  type        = map(string)
}
