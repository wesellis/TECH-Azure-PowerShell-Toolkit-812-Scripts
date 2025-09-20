# Outputs for Azure PowerShell Toolkit Terraform deployment

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.network.vnet_id
}

output "subnet_id" {
  description = "ID of the default subnet"
  value       = module.network.subnet_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = module.storage.primary_blob_endpoint
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = module.compute.vm_name
}

output "vm_public_ip" {
  description = "Public IP address of the virtual machine"
  value       = module.compute.public_ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine"
  value       = module.compute.private_ip_address
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

# Advanced outputs (conditional)
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = var.deploy_advanced ? module.advanced[0].aks_cluster_name : null
}

output "web_app_url" {
  description = "URL of the web application"
  value       = var.deploy_advanced ? module.advanced[0].web_app_url : null
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = var.deploy_advanced ? module.advanced[0].sql_server_fqdn : null
}

# Summary output for easy reference
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment          = var.environment
    location            = var.location
    resource_group      = azurerm_resource_group.main.name
    vm_count           = 1
    storage_accounts   = 1
    advanced_deployed  = var.deploy_advanced
    deployment_time    = timestamp()
  }
}