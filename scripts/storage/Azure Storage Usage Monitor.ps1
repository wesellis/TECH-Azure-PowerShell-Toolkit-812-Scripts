#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Storage Usage Monitor

.DESCRIPTION
    Azure automation for monitoring storage account usage

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
    $LogEntry = "$timestamp [Storage-Monitor] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $Context = $StorageAccount.Context

    Write-Log "Storage Account: $($StorageAccount.StorageAccountName)" "INFO"
    Write-Log "Resource Group: $($StorageAccount.ResourceGroupName)" "INFO"
    Write-Log "Location: $($StorageAccount.Location)" "INFO"
    Write-Log "SKU: $($StorageAccount.Sku.Name)" "INFO"

    # Get containers and their usage
    $Containers = Get-AzStorageContainer -Context $Context
    $TotalSize = 0

    Write-Log "`nContainer Usage:" "INFO"
    foreach ($Container in $Containers) {
        $Blobs = Get-AzStorageBlob -Container $Container.Name -Context $Context
        $ContainerSize = ($Blobs | Measure-Object -Property Length -Sum).Sum
        $SizeInMB = [Math]::Round($ContainerSize / 1MB, 2)
        Write-Log "  $($Container.Name): $SizeInMB MB" "INFO"
        $TotalSize += $ContainerSize
    }

    $TotalSizeInGB = [Math]::Round($TotalSize / 1GB, 2)
    Write-Log "`nTotal Storage Used: $TotalSizeInGB GB" "SUCCESS"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}