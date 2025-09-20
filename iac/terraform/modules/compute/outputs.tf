output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.name
}

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.id
}

output "public_ip_address" {
  description = "Public IP address of the virtual machine"
  value       = azurerm_public_ip.vm_public_ip.ip_address
}

output "public_ip_fqdn" {
  description = "Fully qualified domain name of the public IP"
  value       = azurerm_public_ip.vm_public_ip.fqdn
}

output "private_ip_address" {
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.vm_nic.id
}

output "vm_identity_principal_id" {
  description = "Principal ID of the VM's system assigned identity"
  value       = azurerm_windows_virtual_machine.main.identity[0].principal_id
}

output "vm_identity_tenant_id" {
  description = "Tenant ID of the VM's system assigned identity"
  value       = azurerm_windows_virtual_machine.main.identity[0].tenant_id
}

output "backup_vault_id" {
  description = "ID of the backup vault"
  value       = var.environment == "prod" && var.enable_backup ? azurerm_recovery_services_vault.vm_backup[0].id : null
}

output "backup_policy_id" {
  description = "ID of the backup policy"
  value       = var.environment == "prod" && var.enable_backup ? azurerm_backup_policy_vm.vm_backup_policy[0].id : null
}

output "admin_password" {
  description = "Administrator password (if generated)"
  value       = var.admin_password != null ? var.admin_password : (length(random_password.vm_password) > 0 ? random_password.vm_password[0].result : null)
  sensitive   = true
}