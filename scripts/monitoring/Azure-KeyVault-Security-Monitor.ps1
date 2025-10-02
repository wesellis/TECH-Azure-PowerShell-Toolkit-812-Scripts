#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
    Manage Key Vault

.DESCRIPTION
    Manage Key Vault
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$VaultName
)
Write-Output "Monitoring Key Vault: $VaultName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName
Write-Output "Key Vault Information:"
Write-Output "Vault Name: $($KeyVault.VaultName)"
Write-Output "Location: $($KeyVault.Location)"
Write-Output "Vault URI: $($KeyVault.VaultUri)"
Write-Output "SKU: $($KeyVault.Sku)"
Write-Output "Tenant ID: $($KeyVault.TenantId)"
Write-Output "`nSecurity Configuration:"
Write-Output "Enabled for Deployment: $($KeyVault.EnabledForDeployment)"
Write-Output "Enabled for Disk Encryption: $($KeyVault.EnabledForDiskEncryption)"
Write-Output "Enabled for Template Deployment: $($KeyVault.EnabledForTemplateDeployment)"
Write-Output "Soft Delete Enabled: $($KeyVault.EnableSoftDelete)"
Write-Output "Purge Protection Enabled: $($KeyVault.EnablePurgeProtection)"
Write-Output "`nAccess Policies: $($KeyVault.AccessPolicies.Count)"
foreach ($Policy in $KeyVault.AccessPolicies) {
    Write-Output "  - Object ID: $($Policy.ObjectId)"
    Write-Output "    Application ID: $($Policy.ApplicationId)"
    Write-Output "    Permissions to Keys: $($Policy.PermissionsToKeys -join ', ')"
    Write-Output "    Permissions to Secrets: $($Policy.PermissionsToSecrets -join ', ')"
    Write-Output "    Permissions to Certificates: $($Policy.PermissionsToCertificates -join ', ')"
    Write-Output "    ---"
}
try {
    $Secrets = Get-AzKeyVaultSecret -VaultName $VaultName
    $Keys = Get-AzKeyVaultKey -VaultName $VaultName
    $Certificates = Get-AzKeyVaultCertificate -VaultName $VaultName
    Write-Output "`nVault Contents:"
    Write-Output "Secrets: $($Secrets.Count)"
    Write-Output "Keys: $($Keys.Count)"
    Write-Output "Certificates: $($Certificates.Count)"
} catch {
    Write-Output "`nVault Contents: Unable to access (check permissions)"
}
Write-Output "`nKey Vault monitoring completed at $(Get-Date)"



