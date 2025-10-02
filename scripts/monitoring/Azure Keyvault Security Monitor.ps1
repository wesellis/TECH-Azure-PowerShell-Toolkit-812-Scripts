#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
    Azure Keyvault Security Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$VaultName
)
Write-Output "Monitoring Key Vault: $VaultName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output " ============================================" "INFO"
    [string]$KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName
Write-Output "Key Vault Information:" "INFO"
Write-Output "Vault Name: $($KeyVault.VaultName)" "INFO"
Write-Output "Location: $($KeyVault.Location)" "INFO"
Write-Output "Vault URI: $($KeyVault.VaultUri)" "INFO"
Write-Output "SKU: $($KeyVault.Sku)" "INFO"
Write-Output "Tenant ID: $($KeyVault.TenantId)" "INFO"
Write-Output " `nSecurity Configuration:" "INFO"
Write-Output "Enabled for Deployment: $($KeyVault.EnabledForDeployment)" "INFO"
Write-Output "Enabled for Disk Encryption: $($KeyVault.EnabledForDiskEncryption)" "INFO"
Write-Output "Enabled for Template Deployment: $($KeyVault.EnabledForTemplateDeployment)" "INFO"
Write-Output "Soft Delete Enabled: $($KeyVault.EnableSoftDelete)" "INFO"
Write-Output "Purge Protection Enabled: $($KeyVault.EnablePurgeProtection)" "INFO"
Write-Output " `nAccess Policies: $($KeyVault.AccessPolicies.Count)" "INFO"
foreach ($Policy in $KeyVault.AccessPolicies) {
    Write-Output "  - Object ID: $($Policy.ObjectId)" "INFO"
    Write-Output "    Application ID: $($Policy.ApplicationId)" "INFO"
    Write-Output "    Permissions to Keys: $($Policy.PermissionsToKeys -join ', ')" "INFO"
    Write-Output "    Permissions to Secrets: $($Policy.PermissionsToSecrets -join ', ')" "INFO"
    Write-Output "    Permissions to Certificates: $($Policy.PermissionsToCertificates -join ', ')" "INFO"
    Write-Output "    ---" "INFO"
}
try {
    [string]$Secrets = Get-AzKeyVaultSecret -VaultName $VaultName
    [string]$Keys = Get-AzKeyVaultKey -VaultName $VaultName
    [string]$Certificates = Get-AzKeyVaultCertificate -VaultName $VaultName
    Write-Output " `nVault Contents:" "INFO"
    Write-Output "Secrets: $($Secrets.Count)" "INFO"
    Write-Output "Keys: $($Keys.Count)" "INFO"
    Write-Output "Certificates: $($Certificates.Count)" "INFO"
} catch {
    Write-Output " `nVault Contents: Unable to access (check permissions)" "INFO"
}
Write-Output " `nKey Vault monitoring completed at $(Get-Date)" "INFO"



