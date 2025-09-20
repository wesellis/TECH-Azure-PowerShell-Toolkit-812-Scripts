# Terraform backend configuration for Azure PowerShell Toolkit

terraform {
  required_version = ">= 1.5"

  # Configure remote state storage in Azure Storage
  backend "azurerm" {
    # These values should be set via environment variables or backend config file
    # Example:
    # export ARM_ACCESS_KEY="storage_account_access_key"
    # terraform init -backend-config="storage_account_name=tfstate" -backend-config="container_name=tfstate" -backend-config="key=terraform.tfstate"

    # Storage account name (set via -backend-config or environment)
    # storage_account_name = "tfstatestorage"

    # Container name for state files
    # container_name = "tfstate"

    # State file name
    # key = "terraform.tfstate"

    # Resource group containing the storage account
    # resource_group_name = "tfstate-rg"

    # Use managed identity or service principal authentication
    use_msi = false
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}