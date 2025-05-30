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

Write-Host "Monitoring Key Vault: $VaultName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get Key Vault details
$KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName

Write-Host "Key Vault Information:"
Write-Host "  Vault Name: $($KeyVault.VaultName)"
Write-Host "  Location: $($KeyVault.Location)"
Write-Host "  Vault URI: $($KeyVault.VaultUri)"
Write-Host "  SKU: $($KeyVault.Sku)"
Write-Host "  Tenant ID: $($KeyVault.TenantId)"

# Security settings
Write-Host "`nSecurity Configuration:"
Write-Host "  Enabled for Deployment: $($KeyVault.EnabledForDeployment)"
Write-Host "  Enabled for Disk Encryption: $($KeyVault.EnabledForDiskEncryption)"
Write-Host "  Enabled for Template Deployment: $($KeyVault.EnabledForTemplateDeployment)"
Write-Host "  Soft Delete Enabled: $($KeyVault.EnableSoftDelete)"
Write-Host "  Purge Protection Enabled: $($KeyVault.EnablePurgeProtection)"

# Access policies
Write-Host "`nAccess Policies: $($KeyVault.AccessPolicies.Count)"
foreach ($Policy in $KeyVault.AccessPolicies) {
    Write-Host "  - Object ID: $($Policy.ObjectId)"
    Write-Host "    Application ID: $($Policy.ApplicationId)"
    Write-Host "    Permissions to Keys: $($Policy.PermissionsToKeys -join ', ')"
    Write-Host "    Permissions to Secrets: $($Policy.PermissionsToSecrets -join ', ')"
    Write-Host "    Permissions to Certificates: $($Policy.PermissionsToCertificates -join ', ')"
    Write-Host "    ---"
}

# Get vault contents summary
try {
    $Secrets = Get-AzKeyVaultSecret -VaultName $VaultName
    $Keys = Get-AzKeyVaultKey -VaultName $VaultName
    $Certificates = Get-AzKeyVaultCertificate -VaultName $VaultName
    
    Write-Host "`nVault Contents:"
    Write-Host "  Secrets: $($Secrets.Count)"
    Write-Host "  Keys: $($Keys.Count)"
    Write-Host "  Certificates: $($Certificates.Count)"
} catch {
    Write-Host "`nVault Contents: Unable to access (check permissions)"
}

Write-Host "`nKey Vault monitoring completed at $(Get-Date)"
