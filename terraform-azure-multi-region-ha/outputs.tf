output "traffic_manager_fqdn" {
  description = "Global DNS name clients use for Traffic Manager failover."
  value       = module.global_traffic_manager.traffic_manager_fqdn
}

output "traffic_manager_endpoint_priorities" {
  description = "Effective TM endpoint priorities after forced-failover toggle."
  value       = local.endpoint_priorities
}

output "regional_public_fqdns" {
  description = "Regional load balancer DNS endpoints used by Traffic Manager."
  value = {
    for key, lb in module.regional_load_balancer :
    key => lb.public_ip_fqdn
  }
}

output "regional_resource_groups" {
  description = "Resource groups created for each region role."
  value = {
    for key, foundation in module.regional_foundation :
    key => foundation.resource_group_name
  }
}

output "regional_vmss_names" {
  description = "VM Scale Set names for each region role."
  value = {
    for key, compute in module.regional_compute :
    key => compute.vmss_name
  }
}

output "aks_cluster_names" {
  description = "AKS cluster names by region role for enabled AKS regions."
  value = {
    for key, aks in module.aks_kubernetes :
    key => aks.cluster_name
  }
}

output "aks_kubeconfig_commands" {
  description = "CLI helper commands to fetch kubeconfig for each AKS cluster."
  value = {
    for key, aks in module.aks_kubernetes :
    key => aks.kube_admin_config_command
  }
}

output "aks_persistent_storage_accounts" {
  description = "Storage account names for AKS persistent volumes by region."
  value = {
    for key, storage in module.aks_persistent_storage :
    key => storage.storage_account_name
  }
}

output "aks_persistent_storage_shares" {
  description = "Azure Files share names for AKS persistent volumes by region."
  value = {
    for key, storage in module.aks_persistent_storage :
    key => storage.storage_share_name
  }
}

output "aks_persistent_volume_k8s_hints" {
  description = "Kubernetes secret hints for Azure Files static PV setup."
  value = {
    for key, storage in module.aks_persistent_storage :
    key => {
      resource_group_name = storage.resource_group_name
      storage_account     = storage.storage_account_name
      storage_share       = storage.storage_share_name
      secret_name         = storage.kubernetes_secret_name
    }
  }
}

output "regional_compute_cost_profile" {
  description = "Effective cost profile for regional compute and Spot usage."
  value = {
    primary = {
      vm_sku    = var.primary_vm_sku
      instances = var.primary_vm_instances
      use_spot  = false
    }
    secondary = {
      vm_sku    = var.secondary_vm_sku
      instances = var.secondary_vm_instances
      use_spot  = var.enable_secondary_spot
    }
  }
}

output "security_configuration" {
  description = "Effective baseline security controls for ingress and SSH."
  value = {
    allowed_http_source_cidrs = var.allowed_http_source_cidrs
    enable_ssh_access         = var.enable_ssh_access
    allowed_ssh_source_cidrs  = var.allowed_ssh_source_cidrs
  }
}

output "dr_storage_account_name" {
  description = "Geo-redundant storage account for DR artifacts and fallback."
  value       = module.dr_storage_fallback.storage_account_name
}

output "dr_backup_container_name" {
  description = "Private blob container intended for DR backup artifacts."
  value       = module.dr_storage_fallback.dr_backup_container_name
}

output "fallback_website_url" {
  description = "Fallback maintenance URL used as final TM endpoint."
  value = (
    var.enable_fallback_website ?
    "https://${module.dr_storage_fallback.primary_web_host}" :
    null
  )
}
