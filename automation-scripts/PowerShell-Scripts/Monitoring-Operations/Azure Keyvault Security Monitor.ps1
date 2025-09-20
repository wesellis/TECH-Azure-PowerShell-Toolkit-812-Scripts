<#
.SYNOPSIS
    Azure Keyvault Security Monitor

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$VaultName
)
Write-Host "Monitoring Key Vault: $VaultName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host " ============================================" "INFO"
$KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName
Write-Host "Key Vault Information:" "INFO"
Write-Host "Vault Name: $($KeyVault.VaultName)" "INFO"
Write-Host "Location: $($KeyVault.Location)" "INFO"
Write-Host "Vault URI: $($KeyVault.VaultUri)" "INFO"
Write-Host "SKU: $($KeyVault.Sku)" "INFO"
Write-Host "Tenant ID: $($KeyVault.TenantId)" "INFO"
Write-Host " `nSecurity Configuration:" "INFO"
Write-Host "Enabled for Deployment: $($KeyVault.EnabledForDeployment)" "INFO"
Write-Host "Enabled for Disk Encryption: $($KeyVault.EnabledForDiskEncryption)" "INFO"
Write-Host "Enabled for Template Deployment: $($KeyVault.EnabledForTemplateDeployment)" "INFO"
Write-Host "Soft Delete Enabled: $($KeyVault.EnableSoftDelete)" "INFO"
Write-Host "Purge Protection Enabled: $($KeyVault.EnablePurgeProtection)" "INFO"
Write-Host " `nAccess Policies: $($KeyVault.AccessPolicies.Count)" "INFO"
foreach ($Policy in $KeyVault.AccessPolicies) {
    Write-Host "  - Object ID: $($Policy.ObjectId)" "INFO"
    Write-Host "    Application ID: $($Policy.ApplicationId)" "INFO"
    Write-Host "    Permissions to Keys: $($Policy.PermissionsToKeys -join ', ')" "INFO"
    Write-Host "    Permissions to Secrets: $($Policy.PermissionsToSecrets -join ', ')" "INFO"
    Write-Host "    Permissions to Certificates: $($Policy.PermissionsToCertificates -join ', ')" "INFO"
    Write-Host "    ---" "INFO"
}
try {
    $Secrets = Get-AzKeyVaultSecret -VaultName $VaultName
$Keys = Get-AzKeyVaultKey -VaultName $VaultName
$Certificates = Get-AzKeyVaultCertificate -VaultName $VaultName
    Write-Host " `nVault Contents:" "INFO"
    Write-Host "Secrets: $($Secrets.Count)" "INFO"
    Write-Host "Keys: $($Keys.Count)" "INFO"
    Write-Host "Certificates: $($Certificates.Count)" "INFO"
} catch {
    Write-Host " `nVault Contents: Unable to access (check permissions)" "INFO"
}
Write-Host " `nKey Vault monitoring completed at $(Get-Date)" "INFO"\n