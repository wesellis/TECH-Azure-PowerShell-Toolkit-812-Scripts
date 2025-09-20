#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure Storage Keys Retriever

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$StorageAccountName
)
Write-Host "Retrieving access keys for Storage Account: $StorageAccountName" "INFO"

$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
Write-Host " `nStorage Account Keys:" "INFO"
Write-Host "Primary Key: $($Keys[0].Value)" "INFO"
Write-Host "Secondary Key: $($Keys[1].Value)" "INFO"
Write-Host " `nConnection Strings:" "INFO"
Write-Host "Primary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[0].Value);EndpointSuffix=core.windows.net" "INFO"
Write-Host "Secondary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[1].Value);EndpointSuffix=core.windows.net" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


