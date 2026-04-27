variable "storage_account_name" {
  description = "Globally unique storage account name for DR and fallback."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where DR storage resources are created."
  type        = string
}

variable "location" {
  description = "Azure location for the DR storage account."
  type        = string
}

variable "dr_data_retention_days" {
  description = "Retention period for DR artifacts and soft-delete policies."
  type        = number
}

variable "enable_fallback_website" {
  description = "Controls whether static fallback pages are uploaded."
  type        = bool
}

variable "fallback_index_html" {
  description = "HTML content served by the fallback maintenance endpoint."
  type        = string
}

variable "common_tags" {
  description = "Common tags merged into all resources."
  type        = map(string)
}
