# Networking Module
# Creates a virtual network with configurable subnets and security groups

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes

  # Service endpoints
  service_endpoints = lookup(each.value, "service_endpoints", [])

  # Subnet delegation
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", [])
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "nsg" {
  for_each = { for subnet_name, subnet in var.subnets : subnet_name => subnet if lookup(subnet, "create_nsg", true) }

  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Default security rules based on subnet purpose
  dynamic "security_rule" {
    for_each = lookup(each.value, "security_rules", local.default_security_rules[lookup(each.value, "purpose", "general")])
    content {
      name                         = security_rule.value.name
      priority                     = security_rule.value.priority
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range            = lookup(security_rule.value, "source_port_range", null)
      destination_port_range       = lookup(security_rule.value, "destination_port_range", null)
      source_port_ranges           = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_ranges      = lookup(security_rule.value, "destination_port_ranges", null)
      source_address_prefix        = lookup(security_rule.value, "source_address_prefix", null)
      destination_address_prefix   = lookup(security_rule.value, "destination_address_prefix", null)
      source_address_prefixes      = lookup(security_rule.value, "source_address_prefixes", null)
      destination_address_prefixes = lookup(security_rule.value, "destination_address_prefixes", null)
    }
  }
}

# NSG to Subnet Association
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = { for subnet_name, subnet in var.subnets : subnet_name => subnet if lookup(subnet, "create_nsg", true) }

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

# Route Tables (optional)
resource "azurerm_route_table" "route_table" {
  for_each = { for subnet_name, subnet in var.subnets : subnet_name => subnet if lookup(subnet, "create_route_table", false) }

  name                = "${each.key}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "route" {
    for_each = lookup(each.value, "routes", [])
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
}

# Route Table to Subnet Association
resource "azurerm_subnet_route_table_association" "route_association" {
  for_each = { for subnet_name, subnet in var.subnets : subnet_name => subnet if lookup(subnet, "create_route_table", false) }

  subnet_id      = azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.route_table[each.key].id
}

# NAT Gateway (for outbound internet access)
resource "azurerm_public_ip" "nat_gateway_ip" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = "${var.vnet_name}-nat-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.nat_gateway_zones
  tags                = var.tags
}

resource "azurerm_nat_gateway" "nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  name                    = "${var.vnet_name}-nat"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = var.nat_gateway_zones
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_association" {
  count = var.enable_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.nat_gateway[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip[0].id
}

# Local values for default security rules
locals {
  default_security_rules = {
    web = [
      {
        name                       = "Allow-HTTP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow-HTTPS"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
    app = [
      {
        name                       = "Allow-App-Tier"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["8080", "8443"]
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
    ]
    data = [
      {
        name                       = "Allow-SQL"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
    ]
    general = []
  }
}