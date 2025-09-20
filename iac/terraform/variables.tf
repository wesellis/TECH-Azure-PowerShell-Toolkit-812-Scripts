# Variables for Azure PowerShell Toolkit Terraform deployment

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "toolkit"

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 10
    error_message = "Project name must be between 3 and 10 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US"
}

variable "admin_username" {
  description = "Administrator username for VMs"
  type        = string
  default     = "azureadmin"

  validation {
    condition     = length(var.admin_username) >= 3 && length(var.admin_username) <= 20
    error_message = "Admin username must be between 3 and 20 characters."
  }
}

variable "admin_password" {
  description = "Administrator password for VMs"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Admin password must be at least 12 characters long."
  }
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B2s"

  validation {
    condition = contains([
      "Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_E2s_v3"
    ], var.vm_size)
    error_message = "VM size must be a valid Azure VM size."
  }
}

variable "deploy_advanced" {
  description = "Deploy advanced resources (AKS, App Service, SQL Database)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Owner       = "Azure-Toolkit-Team"
    CostCenter  = "IT-Operations"
    Compliance  = "Standard"
  }
}