# Key Vault module for Azure PowerShell Toolkit

data "azurerm_client_config" "current" {}

resource "random_string" "keyvault_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "${var.resource_prefix}-kv-${random_string.keyvault_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id          = var.tenant_id
  sku_name           = "standard"

  # Security configurations
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = var.environment == "prod" ? true : false
  soft_delete_retention_days      = var.environment == "prod" ? 90 : 7

  # Network access configuration
  public_network_access_enabled = true
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Access policy for the current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.object_id

  key_permissions = [
    "Get", "List", "Create", "Update", "Import", "Delete", "Backup", "Restore",
    "Decrypt", "Encrypt", "Sign", "UnwrapKey", "Verify", "WrapKey"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Update", "Import", "Delete", "Backup", "Restore",
    "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
  ]
}

# Access policy for Azure services (if needed)
resource "azurerm_key_vault_access_policy" "azure_services" {
  count = var.enable_azure_services_access ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = "00000000-0000-0000-0000-000000000000"  # Azure services object ID

  secret_permissions = [
    "Get", "List"
  ]

  key_permissions = [
    "Get", "List", "Decrypt", "Encrypt"
  ]
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${azurerm_key_vault.main.name}-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Sample secrets for demonstration (in production, these should be set externally)
resource "azurerm_key_vault_secret" "demo_secret" {
  count = var.create_demo_secrets ? 1 : 0

  name         = "demo-secret"
  value        = "DemoSecretValue123!"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = merge(var.tags, {
    Purpose = "Demo"
  })
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  count = var.create_demo_secrets ? 1 : 0

  name         = "storage-connection-string"
  value        = "DefaultEndpointsProtocol=https;AccountName=placeholder;AccountKey=placeholder;EndpointSuffix=core.windows.net"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = merge(var.tags, {
    Purpose = "Configuration"
  })
}

# Key for encryption
resource "azurerm_key_vault_key" "encryption_key" {
  count = var.create_encryption_key ? 1 : 0

  name         = "encryption-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = merge(var.tags, {
    Purpose = "Encryption"
  })
}