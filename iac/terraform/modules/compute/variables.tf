variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "subnet_id" {
  description = "ID of the subnet for VM placement"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Administrator password for the VM"
  type        = string
  sensitive   = true
  default     = null
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 128
}

variable "data_disk_size_gb" {
  description = "Size of the data disk in GB (0 to disable)"
  type        = number
  default     = 256
}

variable "vm_image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "vm_image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "WindowsServer"
}

variable "vm_image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "2022-datacenter-azure-edition"
}

variable "vm_image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

variable "boot_diagnostics_storage_uri" {
  description = "URI of storage account for boot diagnostics"
  type        = string
  default     = null
}

variable "allowed_ssh_source_ranges" {
  description = "List of IP ranges allowed for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "allowed_rdp_source_ranges" {
  description = "List of IP ranges allowed for RDP access"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "allowed_ps_remoting_source_ranges" {
  description = "List of IP ranges allowed for PowerShell remoting"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "enable_backup" {
  description = "Enable Azure Backup for the VM"
  type        = bool
  default     = false
}

variable "install_azure_powershell" {
  description = "Install Azure PowerShell on the VM"
  type        = bool
  default     = true
}

variable "azure_powershell_install_script_url" {
  description = "URL of the Azure PowerShell installation script"
  type        = string
  default     = "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/install-powershell.ps1"
}

variable "dsc_configuration_url" {
  description = "URL of the DSC configuration"
  type        = string
  default     = ""
}

variable "dsc_registration_key" {
  description = "DSC registration key"
  type        = string
  sensitive   = true
  default     = ""
}