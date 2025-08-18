# ============================================================================
# Script Name: Azure Key Vault Security Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Key Vault security, access policies, and secret management
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VaultName
)

Write-Information "Monitoring Key Vault: $VaultName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get Key Vault details
$KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName

Write-Information "Key Vault Information:"
Write-Information "  Vault Name: $($KeyVault.VaultName)"
Write-Information "  Location: $($KeyVault.Location)"
Write-Information "  Vault URI: $($KeyVault.VaultUri)"
Write-Information "  SKU: $($KeyVault.Sku)"
Write-Information "  Tenant ID: $($KeyVault.TenantId)"

# Security settings
Write-Information "`nSecurity Configuration:"
Write-Information "  Enabled for Deployment: $($KeyVault.EnabledForDeployment)"
Write-Information "  Enabled for Disk Encryption: $($KeyVault.EnabledForDiskEncryption)"
Write-Information "  Enabled for Template Deployment: $($KeyVault.EnabledForTemplateDeployment)"
Write-Information "  Soft Delete Enabled: $($KeyVault.EnableSoftDelete)"
Write-Information "  Purge Protection Enabled: $($KeyVault.EnablePurgeProtection)"

# Access policies
Write-Information "`nAccess Policies: $($KeyVault.AccessPolicies.Count)"
foreach ($Policy in $KeyVault.AccessPolicies) {
    Write-Information "  - Object ID: $($Policy.ObjectId)"
    Write-Information "    Application ID: $($Policy.ApplicationId)"
    Write-Information "    Permissions to Keys: $($Policy.PermissionsToKeys -join ', ')"
    Write-Information "    Permissions to Secrets: $($Policy.PermissionsToSecrets -join ', ')"
    Write-Information "    Permissions to Certificates: $($Policy.PermissionsToCertificates -join ', ')"
    Write-Information "    ---"
}

# Get vault contents summary
try {
    $Secrets = Get-AzKeyVaultSecret -VaultName $VaultName
    $Keys = Get-AzKeyVaultKey -VaultName $VaultName
    $Certificates = Get-AzKeyVaultCertificate -VaultName $VaultName
    
    Write-Information "`nVault Contents:"
    Write-Information "  Secrets: $($Secrets.Count)"
    Write-Information "  Keys: $($Keys.Count)"
    Write-Information "  Certificates: $($Certificates.Count)"
} catch {
    Write-Information "`nVault Contents: Unable to access (check permissions)"
}

Write-Information "`nKey Vault monitoring completed at $(Get-Date)"
