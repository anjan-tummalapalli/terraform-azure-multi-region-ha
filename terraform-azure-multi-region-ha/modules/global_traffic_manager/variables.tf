variable "base_name" {
  description = "Base name prefix shared across resources."
  type        = string
}

variable "project_name" {
  description = "Project prefix used for Traffic Manager DNS label."
  type        = string
}

variable "unique_suffix" {
  description = "Random suffix used to ensure DNS uniqueness."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group hosting the Traffic Manager profile."
  type        = string
}

variable "regional_targets" {
  description = "Map of regional endpoint hostnames keyed by region role."
  type        = map(string)
}

variable "endpoint_priorities" {
  description = "Priority map controlling active/failover order for endpoints."
  type        = map(number)
}

variable "enable_fallback_website" {
  description = "Controls whether fallback endpoint is created in Traffic Manager."
  type        = bool
}

variable "fallback_target" {
  description = "Fallback website hostname used for last-resort routing."
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags merged into all resources."
  type        = map(string)
}
