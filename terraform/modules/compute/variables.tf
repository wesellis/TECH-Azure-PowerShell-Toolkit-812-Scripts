# Compute Module Variables

variable "vm_name" {
  description = "Base name for virtual machines"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_name))
    error_message = "VM name must be 1-15 characters and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "instance_count" {
  description = "Number of VM instances to create"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 100
    error_message = "Instance count must be between 1 and 100."
  }
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B2s"
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be either 'Linux' or 'Windows'."
  }
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Administrator password (leave empty for auto-generation)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "disable_password_authentication" {
  description = "Disable password authentication for Linux VMs"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for Linux VMs (required if password auth is disabled)"
  type        = string
  default     = null
}

# Networking
variable "subnet_id" {
  description = "Subnet ID where VMs will be placed"
  type        = string
}

variable "network_security_group_id" {
  description = "Network security group ID to associate with NICs"
  type        = string
  default     = null
}

variable "create_public_ip" {
  description = "Create public IP addresses for VMs"
  type        = bool
  default     = false
}

variable "private_ip_allocation_method" {
  description = "Private IP allocation method"
  type        = string
  default     = "Dynamic"
  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_allocation_method)
    error_message = "Private IP allocation method must be 'Dynamic' or 'Static'."
  }
}

variable "private_ip_addresses" {
  description = "List of static private IP addresses (required if allocation method is Static)"
  type        = list(string)
  default     = []
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking"
  type        = bool
  default     = false
}

# High Availability
variable "availability_zones" {
  description = "Availability zones for VMs"
  type        = list(string)
  default     = []
}

variable "enable_availability_set" {
  description = "Create and use availability set"
  type        = bool
  default     = false
}

variable "enable_proximity_placement_group" {
  description = "Create and use proximity placement group"
  type        = bool
  default     = false
}

# Storage
variable "os_disk_caching" {
  description = "OS disk caching type"
  type        = string
  default     = "ReadWrite"
  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk_caching)
    error_message = "OS disk caching must be 'None', 'ReadOnly', or 'ReadWrite'."
  }
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "Premium_LRS"
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"
    ], var.os_disk_storage_account_type)
    error_message = "Invalid storage account type."
  }
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = null
}

variable "enable_ephemeral_os_disk" {
  description = "Enable ephemeral OS disk (requires supported VM size)"
  type        = bool
  default     = false
}

variable "data_disk_count" {
  description = "Number of data disks per VM"
  type        = number
  default     = 0
  validation {
    condition     = var.data_disk_count >= 0 && var.data_disk_count <= 32
    error_message = "Data disk count must be between 0 and 32."
  }
}

variable "data_disk_size_gb" {
  description = "Size of each data disk in GB"
  type        = number
  default     = 128
}

variable "data_disk_storage_account_type" {
  description = "Data disk storage account type"
  type        = string
  default     = "Premium_LRS"
}

variable "data_disk_caching" {
  description = "Data disk caching type"
  type        = string
  default     = "ReadWrite"
}

# Image
variable "image_publisher" {
  description = "VM image publisher"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "VM image offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  description = "VM image SKU"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "image_version" {
  description = "VM image version"
  type        = string
  default     = "latest"
}

# Windows-specific
variable "enable_automatic_updates" {
  description = "Enable automatic updates for Windows VMs"
  type        = bool
  default     = true
}

variable "timezone" {
  description = "Timezone for Windows VMs"
  type        = string
  default     = "UTC"
}

variable "additional_unattend_content" {
  description = "Additional unattend content for Windows VMs"
  type = list(object({
    content = string
    setting = string
  }))
  default = []
}

# General
variable "enable_system_assigned_identity" {
  description = "Enable system-assigned managed identity"
  type        = bool
  default     = true
}

variable "custom_data" {
  description = "Custom data to pass to VMs"
  type        = string
  default     = null
}

variable "boot_diagnostics_storage_account_uri" {
  description = "Storage account URI for boot diagnostics (null for managed storage)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}