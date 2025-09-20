# Networking Module Outputs

output "vnet_id" {
  description = "Virtual network resource ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Virtual network address space"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to address prefixes"
  value       = { for k, v in azurerm_subnet.subnets : k => v.address_prefixes }
}

output "nsg_ids" {
  description = "Map of NSG names to IDs"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}

output "route_table_ids" {
  description = "Map of route table names to IDs"
  value       = { for k, v in azurerm_route_table.route_table : k => v.id }
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if created)"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.nat_gateway[0].id : null
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP address (if created)"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat_gateway_ip[0].ip_address : null
}