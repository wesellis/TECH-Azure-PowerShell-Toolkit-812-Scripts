#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Keyvault Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
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
;
[CmdletBinding()]
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
Write-Output "Provisioning Key Vault: $VaultName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "SKU: $SkuName"
    $params = @{
    Sku = $SkuName
    ErrorAction = "Stop"
    VaultName = $VaultName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
    [string]$KeyVault @params
Write-Output "Key Vault $VaultName provisioned successfully"
Write-Output "Vault URI: $($KeyVault.VaultUri)"
Write-Output "Enabled for Deployment: $EnabledForDeployment"
Write-Output "Enabled for Template Deployment: $EnabledForTemplateDeployment"
Write-Output "Enabled for Disk Encryption: $EnabledForDiskEncryption"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
