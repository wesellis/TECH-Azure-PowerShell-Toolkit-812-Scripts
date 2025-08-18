<#
.SYNOPSIS
    Azure Keyvault Provisioning Tool

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
    We Enhanced Azure Keyvault Provisioning Tool

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
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



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

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVaultName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [string]$WESkuName = " Standard" ,
    [bool]$WEEnabledForDeployment = $true,
    [bool]$WEEnabledForTemplateDeployment = $true,
    [bool]$WEEnabledForDiskEncryption = $true
)

Write-WELog " Provisioning Key Vault: $WEVaultName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " SKU: $WESkuName" " INFO"

; 
$WEKeyVault = New-AzKeyVault -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -VaultName $WEVaultName `
    -Location $WELocation `
    -Sku $WESkuName `
    -EnabledForDeployment:$WEEnabledForDeployment `
    -EnabledForTemplateDeployment:$WEEnabledForTemplateDeployment `
    -EnabledForDiskEncryption:$WEEnabledForDiskEncryption

Write-WELog " Key Vault $WEVaultName provisioned successfully" " INFO"
Write-WELog " Vault URI: $($WEKeyVault.VaultUri)" " INFO"
Write-WELog " Enabled for Deployment: $WEEnabledForDeployment" " INFO"
Write-WELog " Enabled for Template Deployment: $WEEnabledForTemplateDeployment" " INFO"
Write-WELog " Enabled for Disk Encryption: $WEEnabledForDiskEncryption" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
