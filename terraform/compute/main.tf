terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_name))
    error_message = "VM name must be 1-15 characters and contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B2s", "Standard_D2s_v3",
      "Standard_D4s_v3", "Standard_E2s_v3", "Standard_E4s_v3"
    ], var.vm_size)
    error_message = "VM size must be from the approved list."
  }
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
  default     = "azureuser"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,19}$", var.admin_username))
    error_message = "Username must start with a letter and be 1-20 characters."
  }
}

variable "admin_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^.{12,}$", var.admin_password))
    error_message = "Password must be at least 12 characters long."
  }
}

variable "create_public_ip" {
  description = "Create a public IP address"
  type        = bool
  default     = true
}

variable "network_access" {
  description = "Network access level"
  type        = string
  default     = "restricted"
  validation {
    condition     = contains(["restricted", "open"], var.network_access)
    error_message = "Network access must be either 'restricted' or 'open'."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Local values
locals {
  resource_prefix = "${var.vm_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${local.resource_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Subnet
resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP (conditional)
resource "azurerm_public_ip" "main" {
  count               = var.create_public_ip ? 1 : 0
  name                = "${local.resource_prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.environment == "prod" ? ["1", "2", "3"] : []
  domain_name_label   = "${var.vm_name}-${var.environment}-${random_string.suffix.result}"
  tags                = local.common_tags
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${local.resource_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.network_access == "restricted" ? "10.0.0.0/8" : "*"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      name                       = "DenyAll"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                          = "${local.resource_prefix}-nic"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  enable_accelerated_networking = contains(["Standard_D2s_v3", "Standard_D4s_v3", "Standard_E2s_v3", "Standard_E4s_v3"], var.vm_size)
  tags                          = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.main[0].id : null
  }
}

# Network Interface Security Group Association
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  zone                            = var.environment == "prod" ? "1" : null
  tags                            = local.common_tags

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_password = var.admin_password

  boot_diagnostics {
    storage_account_uri = null
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.environment == "prod" ? "Premium_LRS" : "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Outputs
output "vm_id" {
  description = "Virtual machine resource ID"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Virtual machine name"
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip_address" {
  description = "Public IP address (if created)"
  value       = var.create_public_ip ? azurerm_public_ip.main[0].ip_address : "No public IP created"
}

output "private_ip_address" {
  description = "Private IP address"
  value       = azurerm_network_interface.main.private_ip_address
}

output "fqdn" {
  description = "FQDN (if public IP created)"
  value       = var.create_public_ip ? azurerm_public_ip.main[0].fqdn : "No public IP created"
}

output "ssh_connection" {
  description = "SSH connection command"
  value = var.create_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.main[0].fqdn}" : "ssh ${var.admin_username}@${azurerm_network_interface.main.private_ip_address}"
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}