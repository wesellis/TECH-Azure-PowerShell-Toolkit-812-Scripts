# Storage module for Azure PowerShell Toolkit

resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "${replace(var.resource_prefix, "-", "")}${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                = var.location
  account_tier            = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  account_kind            = "StorageV2"
  access_tier             = "Hot"

  # Security configurations
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  public_network_access_enabled   = true
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled     = true

  # Encryption
  infrastructure_encryption_enabled = var.environment == "prod" ? true : false

  blob_properties {
    delete_retention_policy {
      days = var.environment == "prod" ? 30 : 7
    }
    container_delete_retention_policy {
      days = var.environment == "prod" ? 30 : 7
    }
    versioning_enabled = var.environment == "prod" ? true : false
    change_feed_enabled = var.environment == "prod" ? true : false
  }

  # Network access control
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

# Storage containers
resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "artifacts" {
  name                  = "artifacts"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# File share for shared data
resource "azurerm_storage_share" "shared_data" {
  name                 = "shared-data"
  storage_account_name = azurerm_storage_account.main.name
  quota                = var.environment == "prod" ? 500 : 100
  enabled_protocol     = "SMB"
}

# Table for metadata
resource "azurerm_storage_table" "metadata" {
  name                 = "metadata"
  storage_account_name = azurerm_storage_account.main.name
}

# Queue for processing
resource "azurerm_storage_queue" "processing" {
  name                 = "processing"
  storage_account_name = azurerm_storage_account.main.name
}

# Management policy for lifecycle management
resource "azurerm_storage_management_policy" "main" {
  count = var.environment == "prod" ? 1 : 0

  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "archival-policy"
    enabled = true
    filters {
      prefix_match = ["logs/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }

  rule {
    name    = "backup-retention"
    enabled = true
    filters {
      prefix_match = ["backups/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_archive_after_days_since_modification_greater_than = 7
        delete_after_days_since_modification_greater_than          = 2555  # 7 years
      }
    }
  }
}