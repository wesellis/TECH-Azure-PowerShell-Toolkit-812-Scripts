<#
.SYNOPSIS
    Azure Keyvault Security Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Keyvault Security Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [string]$WEVaultName
)

Write-WELog " Monitoring Key Vault: $WEVaultName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"


$WEKeyVault = Get-AzKeyVault -ResourceGroupName $WEResourceGroupName -VaultName $WEVaultName

Write-WELog " Key Vault Information:" " INFO"
Write-WELog "  Vault Name: $($WEKeyVault.VaultName)" " INFO"
Write-WELog "  Location: $($WEKeyVault.Location)" " INFO"
Write-WELog "  Vault URI: $($WEKeyVault.VaultUri)" " INFO"
Write-WELog "  SKU: $($WEKeyVault.Sku)" " INFO"
Write-WELog "  Tenant ID: $($WEKeyVault.TenantId)" " INFO"


Write-WELog " `nSecurity Configuration:" " INFO"
Write-WELog "  Enabled for Deployment: $($WEKeyVault.EnabledForDeployment)" " INFO"
Write-WELog "  Enabled for Disk Encryption: $($WEKeyVault.EnabledForDiskEncryption)" " INFO"
Write-WELog "  Enabled for Template Deployment: $($WEKeyVault.EnabledForTemplateDeployment)" " INFO"
Write-WELog "  Soft Delete Enabled: $($WEKeyVault.EnableSoftDelete)" " INFO"
Write-WELog "  Purge Protection Enabled: $($WEKeyVault.EnablePurgeProtection)" " INFO"


Write-WELog " `nAccess Policies: $($WEKeyVault.AccessPolicies.Count)" " INFO"
foreach ($WEPolicy in $WEKeyVault.AccessPolicies) {
    Write-WELog "  - Object ID: $($WEPolicy.ObjectId)" " INFO"
    Write-WELog "    Application ID: $($WEPolicy.ApplicationId)" " INFO"
    Write-WELog "    Permissions to Keys: $($WEPolicy.PermissionsToKeys -join ', ')" " INFO"
    Write-WELog "    Permissions to Secrets: $($WEPolicy.PermissionsToSecrets -join ', ')" " INFO"
    Write-WELog "    Permissions to Certificates: $($WEPolicy.PermissionsToCertificates -join ', ')" " INFO"
    Write-WELog "    ---" " INFO"
}


try {
    $WESecrets = Get-AzKeyVaultSecret -VaultName $WEVaultName
   ;  $WEKeys = Get-AzKeyVaultKey -VaultName $WEVaultName
   ;  $WECertificates = Get-AzKeyVaultCertificate -VaultName $WEVaultName
    
    Write-WELog " `nVault Contents:" " INFO"
    Write-WELog "  Secrets: $($WESecrets.Count)" " INFO"
    Write-WELog "  Keys: $($WEKeys.Count)" " INFO"
    Write-WELog "  Certificates: $($WECertificates.Count)" " INFO"
} catch {
    Write-WELog " `nVault Contents: Unable to access (check permissions)" " INFO"
}

Write-WELog " `nKey Vault monitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================