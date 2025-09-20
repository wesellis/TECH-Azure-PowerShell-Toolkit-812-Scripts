# Compute module for Azure PowerShell Toolkit

resource "random_password" "vm_password" {
  count   = var.admin_password == null ? 1 : 0
  length  = 16
  special = true
}

# Public IP for VM
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.resource_prefix}-vm-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                = "Standard"
  domain_name_label  = "${var.resource_prefix}-vm"
  tags               = var.tags
}

# Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.resource_prefix}-vm-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags               = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

# Network Security Group for VM NIC
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.resource_prefix}-vm-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags               = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_source_ranges[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_rdp_source_ranges[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "PowerShell-Remoting"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985-5986"
    source_address_prefix      = var.allowed_ps_remoting_source_ranges[0]
    destination_address_prefix = "*"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name                = "${var.resource_prefix}-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size               = var.vm_size
  admin_username     = var.admin_username
  admin_password     = var.admin_password != null ? var.admin_password : random_password.vm_password[0].result
  tags               = var.tags

  # Disable password authentication and use SSH keys for Linux VMs
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.environment == "prod" ? "Premium_LRS" : "Standard_LRS"
    disk_size_gb        = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_uri
  }

  # Identity
  identity {
    type = "SystemAssigned"
  }
}

# Data disk
resource "azurerm_managed_disk" "data_disk" {
  count = var.data_disk_size_gb > 0 ? 1 : 0

  name                 = "${var.resource_prefix}-vm-data-disk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.environment == "prod" ? "Premium_LRS" : "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                = var.tags
}

# Attach data disk to VM
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk" {
  count = var.data_disk_size_gb > 0 ? 1 : 0

  managed_disk_id    = azurerm_managed_disk.data_disk[0].id
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  lun                = "10"
  caching            = "ReadWrite"
}

# VM Extension for PowerShell configuration
resource "azurerm_virtual_machine_extension" "powershell_dsc" {
  name                 = "PowerShellDSC"
  virtual_machine_id   = azurerm_windows_virtual_machine.main.id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.80"
  tags                = var.tags

  settings = jsonencode({
    wmfVersion = "latest"
    configuration = {
      url      = var.dsc_configuration_url
      script   = "Configuration.ps1"
      function = "Main"
    }
  })

  protected_settings = jsonencode({
    configurationArguments = {
      RegistrationKey = var.dsc_registration_key
    }
  })
}

# VM Extension for Azure PowerShell installation
resource "azurerm_virtual_machine_extension" "azure_powershell" {
  count = var.install_azure_powershell ? 1 : 0

  name                 = "InstallAzurePowerShell"
  virtual_machine_id   = azurerm_windows_virtual_machine.main.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  tags                = var.tags

  settings = jsonencode({
    fileUris = [var.azure_powershell_install_script_url]
  })

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File InstallAzurePowerShell.ps1"
  })
}

# Backup vault and policy (for production)
resource "azurerm_recovery_services_vault" "vm_backup" {
  count = var.environment == "prod" && var.enable_backup ? 1 : 0

  name                = "${var.resource_prefix}-backup-vault"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                = "Standard"
  tags               = var.tags
}

resource "azurerm_backup_policy_vm" "vm_backup_policy" {
  count = var.environment == "prod" && var.enable_backup ? 1 : 0

  name                = "${var.resource_prefix}-backup-policy"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vm_backup[0].name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = 7
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = ["January"]
  }
}

resource "azurerm_backup_protected_vm" "vm_backup_protection" {
  count = var.environment == "prod" && var.enable_backup ? 1 : 0

  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vm_backup[0].name
  source_vm_id        = azurerm_windows_virtual_machine.main.id
  backup_policy_id    = azurerm_backup_policy_vm.vm_backup_policy[0].id
}