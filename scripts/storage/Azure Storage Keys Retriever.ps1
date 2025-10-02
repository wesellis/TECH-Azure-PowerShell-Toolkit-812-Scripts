#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Storage Keys Retriever

.DESCRIPTION
    Azure automation for retrieving storage account keys

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [Storage-Keys] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Retrieving access keys for Storage Account: $StorageAccountName" "INFO"

    $Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

    Write-Log "`nStorage Account Keys:" "SUCCESS"
    Write-Log "Primary Key: $($Keys[0].Value)" "INFO"
    Write-Log "Secondary Key: $($Keys[1].Value)" "INFO"

    Write-Log "`nConnection Strings:" "INFO"
    Write-Log "Primary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[0].Value);EndpointSuffix=core.windows.net" "INFO"
    Write-Log "Secondary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[1].Value);EndpointSuffix=core.windows.net" "INFO"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}