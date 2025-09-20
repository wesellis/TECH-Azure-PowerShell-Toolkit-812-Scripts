#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Storage Usage Monitor

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$StorageAccountName
)
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

$Context = $StorageAccount.Context;
$Usage = Get-AzStorageUsage -Context $Context
Write-Host "Storage Account: $($StorageAccount.StorageAccountName)" "INFO"
Write-Host "Resource Group: $($StorageAccount.ResourceGroupName)" "INFO"
Write-Host "Location: $($StorageAccount.Location)" "INFO"
Write-Host "SKU: $($StorageAccount.Sku.Name)" "INFO"
Write-Host "Usage: $($Usage.CurrentValue) / $($Usage.Limit)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

