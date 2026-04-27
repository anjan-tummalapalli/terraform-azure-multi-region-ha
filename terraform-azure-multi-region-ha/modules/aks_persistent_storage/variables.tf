variable "region_key" {
  description = "Logical region role (primary/secondary)."
  type        = string
}

variable "project_name" {
  description = "Project name prefix used to build globally unique names."
  type        = string
}

variable "unique_suffix" {
  description = "Random suffix used for globally unique naming."
  type        = string
}

variable "location" {
  description = "Azure location where persistent storage is deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name that hosts persistent storage resources."
  type        = string
}

variable "subnet_id" {
  description = "Subnet allowed to access the storage account."
  type        = string
}

variable "account_tier" {
  description = "Storage account performance tier."
  type        = string
}

variable "account_replication_type" {
  description = "Storage account redundancy model."
  type        = string
}

variable "file_share_name" {
  description = "Azure Files share name used for Kubernetes persistent data."
  type        = string
}

variable "share_quota_gb" {
  description = "Azure Files share quota in GiB."
  type        = number
}

variable "common_tags" {
  description = "Common tags merged into persistent storage resources."
  type        = map(string)
}
