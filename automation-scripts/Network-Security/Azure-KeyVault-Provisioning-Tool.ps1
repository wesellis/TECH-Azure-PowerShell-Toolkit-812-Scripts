#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$Location,
    [string]$SkuName = "Standard",
    [bool]$EnabledForDeployment = $true,
    [bool]$EnabledForTemplateDeployment = $true,
    [bool]$EnabledForDiskEncryption = $true
)

#region Functions

Write-Information "Provisioning Key Vault: $VaultName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $SkuName"

# Create the Key Vault
$params = @{
    Sku = $SkuName
    ErrorAction = "Stop"
    VaultName = $VaultName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
$KeyVault @params

Write-Information "Key Vault $VaultName provisioned successfully"
Write-Information "Vault URI: $($KeyVault.VaultUri)"
Write-Information "Enabled for Deployment: $EnabledForDeployment"
Write-Information "Enabled for Template Deployment: $EnabledForTemplateDeployment"
Write-Information "Enabled for Disk Encryption: $EnabledForDiskEncryption"


#endregion
