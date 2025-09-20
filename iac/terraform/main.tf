# Azure PowerShell Toolkit - Terraform Configuration
# Multi-cloud infrastructure as code for enterprise deployments

terraform {
  required_version = ">= 1.5"
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

# Configure Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Local values
locals {
  environment = var.environment
  location    = var.location

  # Resource naming convention
  resource_prefix = "${var.project_name}-${local.environment}-${random_string.suffix.result}"

  # Common tags
  common_tags = merge(var.tags, {
    Environment   = local.environment
    Project      = var.project_name
    ManagedBy    = "Terraform"
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  })
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = local.location
  tags     = local.common_tags
}

# Virtual Network Module
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  resource_prefix    = local.resource_prefix
  tags              = local.common_tags
  environment       = local.environment
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  resource_prefix    = local.resource_prefix
  tags              = local.common_tags
  environment       = local.environment
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  resource_prefix    = local.resource_prefix
  tags              = local.common_tags
  environment       = local.environment
  tenant_id         = data.azurerm_client_config.current.tenant_id
  object_id         = data.azurerm_client_config.current.object_id
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  resource_prefix    = local.resource_prefix
  tags              = local.common_tags
  environment       = local.environment
  subnet_id         = module.network.subnet_id
  admin_username    = var.admin_username
  admin_password    = var.admin_password
  vm_size          = var.vm_size
}

# Advanced resources (conditional)
module "advanced" {
  count  = var.deploy_advanced ? 1 : 0
  source = "./modules/advanced"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  resource_prefix    = local.resource_prefix
  tags              = local.common_tags
  environment       = local.environment
  subnet_id         = module.network.subnet_id
  storage_account_name = module.storage.storage_account_name
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  resource_prefix    = local.resource_prefix
  tags              = local.common_tags
  environment       = local.environment
}