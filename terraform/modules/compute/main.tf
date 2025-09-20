# Compute Module
# Creates virtual machines with advanced configuration options

terraform {
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

# Random password generation (if not provided)
resource "random_password" "admin_password" {
  count = var.admin_password == "" ? 1 : 0

  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Public IP (conditional)
resource "azurerm_public_ip" "vm_public_ip" {
  count = var.create_public_ip ? var.instance_count : 0

  name                = "${var.vm_name}-${count.index + 1}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags

  domain_name_label = "${lower(var.vm_name)}-${count.index + 1}-${random_string.unique_suffix.result}"
}

resource "random_string" "unique_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Network Interface
resource "azurerm_network_interface" "vm_nic" {
  count = var.instance_count

  name                          = "${var.vm_name}-${count.index + 1}-nic"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking
  tags                          = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_allocation_method
    private_ip_address            = var.private_ip_allocation_method == "Static" ? element(var.private_ip_addresses, count.index) : null
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.vm_public_ip[count.index].id : null
  }
}

# Network Interface Security Group Association
resource "azurerm_network_interface_security_group_association" "vm_nsg_association" {
  count = var.network_security_group_id != null ? var.instance_count : 0

  network_interface_id      = azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = var.network_security_group_id
}

# Proximity Placement Group (for high performance scenarios)
resource "azurerm_proximity_placement_group" "vm_ppg" {
  count = var.enable_proximity_placement_group ? 1 : 0

  name                = "${var.vm_name}-ppg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Availability Set (if not using zones)
resource "azurerm_availability_set" "vm_availability_set" {
  count = var.enable_availability_set && length(var.availability_zones) == 0 ? 1 : 0

  name                         = "${var.vm_name}-as"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
  managed                      = true
  proximity_placement_group_id = var.enable_proximity_placement_group ? azurerm_proximity_placement_group.vm_ppg[0].id : null
  tags                         = var.tags
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  count = var.os_type == "Linux" ? var.instance_count : 0

  name                            = var.instance_count > 1 ? "${var.vm_name}-${count.index + 1}" : var.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = var.disable_password_authentication
  zone                            = length(var.availability_zones) > 0 ? element(var.availability_zones, count.index) : null
  availability_set_id             = var.enable_availability_set && length(var.availability_zones) == 0 ? azurerm_availability_set.vm_availability_set[0].id : null
  proximity_placement_group_id    = var.enable_proximity_placement_group ? azurerm_proximity_placement_group.vm_ppg[0].id : null
  tags                            = var.tags

  # Authentication
  admin_password = !var.disable_password_authentication ? (var.admin_password != "" ? var.admin_password : random_password.admin_password[0].result) : null

  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id
  ]

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb

    dynamic "diff_disk_settings" {
      for_each = var.enable_ephemeral_os_disk ? [1] : []
      content {
        option = "Local"
      }
    }
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account_uri
  }

  # Identity
  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Custom data
  custom_data = var.custom_data != null ? base64encode(var.custom_data) : null
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  count = var.os_type == "Windows" ? var.instance_count : 0

  name                = var.instance_count > 1 ? "${var.vm_name}-${count.index + 1}" : var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password != "" ? var.admin_password : random_password.admin_password[0].result
  zone                = length(var.availability_zones) > 0 ? element(var.availability_zones, count.index) : null
  availability_set_id = var.enable_availability_set && length(var.availability_zones) == 0 ? azurerm_availability_set.vm_availability_set[0].id : null
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id
  ]

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account_uri
  }

  # Identity
  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Windows Configuration
  dynamic "additional_unattend_content" {
    for_each = var.additional_unattend_content
    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
    }
  }

  enable_automatic_updates = var.enable_automatic_updates
  timezone                 = var.timezone
  custom_data              = var.custom_data != null ? base64encode(var.custom_data) : null
}

# Data Disks
resource "azurerm_managed_disk" "data_disk" {
  count = var.data_disk_count * var.instance_count

  name                 = "${var.vm_name}-${floor(count.index / var.data_disk_count) + 1}-datadisk-${(count.index % var.data_disk_count) + 1}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  zone                 = length(var.availability_zones) > 0 ? element(var.availability_zones, floor(count.index / var.data_disk_count)) : null
  tags                 = var.tags
}

# Data Disk Attachments
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  count = var.data_disk_count * var.instance_count

  managed_disk_id    = azurerm_managed_disk.data_disk[count.index].id
  virtual_machine_id = var.os_type == "Linux" ? azurerm_linux_virtual_machine.vm[floor(count.index / var.data_disk_count)].id : azurerm_windows_virtual_machine.vm[floor(count.index / var.data_disk_count)].id
  lun                = count.index % var.data_disk_count
  caching            = var.data_disk_caching
}