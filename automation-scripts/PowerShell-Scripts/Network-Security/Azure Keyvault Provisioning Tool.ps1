<#
.SYNOPSIS
    Azure Keyvault Provisioning Tool

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
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
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$SkuName = "Standard" ,
    [bool]$EnabledForDeployment = $true,
    [bool]$EnabledForTemplateDeployment = $true,
    [bool]$EnabledForDiskEncryption = $true
)
Write-Host "Provisioning Key Vault: $VaultName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $SkuName"
$params = @{
    Sku = $SkuName
    ErrorAction = "Stop"
    VaultName = $VaultName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
$KeyVault @params
Write-Host "Key Vault $VaultName provisioned successfully"
Write-Host "Vault URI: $($KeyVault.VaultUri)"
Write-Host "Enabled for Deployment: $EnabledForDeployment"
Write-Host "Enabled for Template Deployment: $EnabledForTemplateDeployment"
Write-Host "Enabled for Disk Encryption: $EnabledForDiskEncryption"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

