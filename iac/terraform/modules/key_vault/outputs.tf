output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "tenant_id" {
  description = "Tenant ID of the Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}

output "encryption_key_id" {
  description = "ID of the encryption key"
  value       = var.create_encryption_key ? azurerm_key_vault_key.encryption_key[0].id : null
}

output "encryption_key_version_id" {
  description = "Version ID of the encryption key"
  value       = var.create_encryption_key ? azurerm_key_vault_key.encryption_key[0].version : null
}