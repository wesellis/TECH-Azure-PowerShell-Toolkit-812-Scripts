#Requires -Version 7.4
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Storage Lifecycle Manager

.DESCRIPTION
    Azure automation for managing storage lifecycle policies

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
    [string]$StorageAccountName,

    [Parameter()]
    [int]$DaysToTierCool = 30,

    [Parameter()]
    [int]$DaysToTierArchive = 90,

    [Parameter()]
    [int]$DaysToDelete = 365
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
    $LogEntry = "$timestamp [Lifecycle] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Configuring lifecycle management for: $StorageAccountName" "INFO"

    $LifecycleRule = @{
        enabled = $true
        name = "DefaultLifecycleRule"
        type = "Lifecycle"
        definition = @{
            filters = @{
                blobTypes = @("blockBlob")
            }
            actions = @{
                baseBlob = @{
                    tierToCool = @{
                        daysAfterModificationGreaterThan = $DaysToTierCool
                    }
                    tierToArchive = @{
                        daysAfterModificationGreaterThan = $DaysToTierArchive
                    }
                    delete = @{
                        daysAfterModificationGreaterThan = $DaysToDelete
                    }
                }
            }
        }
    }

    $PolicyJson = $LifecycleRule | ConvertTo-Json -Depth 10

    $params = @{
        ErrorAction = "Stop"
        Policy = $PolicyJson
        ResourceGroupName = $ResourceGroupName
        StorageAccountName = $StorageAccountName
    }

    Set-AzStorageAccountManagementPolicy @params

    Write-Log "Lifecycle management configured successfully:" "SUCCESS"
    Write-Log "Storage Account: $StorageAccountName" "INFO"
    Write-Log "Tier to Cool: After $DaysToTierCool days" "INFO"
    Write-Log "Tier to Archive: After $DaysToTierArchive days" "INFO"
    Write-Log "Delete: After $DaysToDelete days" "INFO"

    Write-Log "`nLifecycle Benefits:" "INFO"
    Write-Log "  - Automatic cost optimization" "INFO"
    Write-Log "  - Compliance with retention policies" "INFO"
    Write-Log "  - Reduced management overhead" "INFO"
    Write-Log "  - Environmental efficiency" "INFO"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}