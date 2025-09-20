# Compute Module Outputs

output "vm_ids" {
  description = "List of virtual machine resource IDs"
  value = var.os_type == "Linux" ? [
    for vm in azurerm_linux_virtual_machine.vm : vm.id
  ] : [
    for vm in azurerm_windows_virtual_machine.vm : vm.id
  ]
}

output "vm_names" {
  description = "List of virtual machine names"
  value = var.os_type == "Linux" ? [
    for vm in azurerm_linux_virtual_machine.vm : vm.name
  ] : [
    for vm in azurerm_windows_virtual_machine.vm : vm.name
  ]
}

output "private_ip_addresses" {
  description = "List of private IP addresses"
  value = [
    for nic in azurerm_network_interface.vm_nic : nic.private_ip_address
  ]
}

output "public_ip_addresses" {
  description = "List of public IP addresses (if created)"
  value = var.create_public_ip ? [
    for pip in azurerm_public_ip.vm_public_ip : pip.ip_address
  ] : []
}

output "fqdns" {
  description = "List of FQDNs (if public IPs created)"
  value = var.create_public_ip ? [
    for pip in azurerm_public_ip.vm_public_ip : pip.fqdn
  ] : []
}

output "network_interface_ids" {
  description = "List of network interface IDs"
  value = [
    for nic in azurerm_network_interface.vm_nic : nic.id
  ]
}

output "data_disk_ids" {
  description = "List of data disk IDs"
  value = [
    for disk in azurerm_managed_disk.data_disk : disk.id
  ]
}

output "system_assigned_identity_principal_ids" {
  description = "List of system-assigned identity principal IDs"
  value = var.enable_system_assigned_identity ? (
    var.os_type == "Linux" ? [
      for vm in azurerm_linux_virtual_machine.vm : vm.identity[0].principal_id
    ] : [
      for vm in azurerm_windows_virtual_machine.vm : vm.identity[0].principal_id
    ]
  ) : []
}

output "availability_set_id" {
  description = "Availability set ID (if created)"
  value = var.enable_availability_set && length(var.availability_zones) == 0 ? azurerm_availability_set.vm_availability_set[0].id : null
}

output "proximity_placement_group_id" {
  description = "Proximity placement group ID (if created)"
  value = var.enable_proximity_placement_group ? azurerm_proximity_placement_group.vm_ppg[0].id : null
}

output "admin_password" {
  description = "Generated admin password (if auto-generated)"
  value     = var.admin_password == "" ? random_password.admin_password[0].result : "Password provided by user"
  sensitive = true
}

output "connection_commands" {
  description = "Connection commands for VMs"
  value = var.create_public_ip ? [
    for i, pip in azurerm_public_ip.vm_public_ip :
    var.os_type == "Linux" ?
      "ssh ${var.admin_username}@${pip.fqdn}" :
      "mstsc /v:${pip.fqdn}"
  ] : [
    for i, nic in azurerm_network_interface.vm_nic :
    var.os_type == "Linux" ?
      "ssh ${var.admin_username}@${nic.private_ip_address}" :
      "mstsc /v:${nic.private_ip_address}"
  ]
}