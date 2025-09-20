#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Storage Lifecycle Manager

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
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    [Parameter()]
    [int]$DaysToTierCool = 30,
    [Parameter()]
    [int]$DaysToTierArchive = 90,
    [Parameter()]
    [int]$DaysToDelete = 365
)
Write-Host "Configuring lifecycle management for: $StorageAccountName" "INFO"

$LifecycleRule = @{
    enabled = $true
    name = "DefaultLifecycleRule"
    type = "Lifecycle"
    definition = @{
        filters = @{
            blobTypes = @(" blockBlob" )
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
Write-Host "Lifecycle management configured successfully:" "INFO"
Write-Host "Storage Account: $StorageAccountName" "INFO"
Write-Host "Tier to Cool: After $DaysToTierCool days" "INFO"
Write-Host "Tier to Archive: After $DaysToTierArchive days" "INFO"
Write-Host "Delete: After $DaysToDelete days" "INFO"
Write-Host " `nLifecycle Benefits:" "INFO"
Write-Host "Automatic cost optimization" "INFO"
Write-Host "Compliance with retention policies" "INFO"
Write-Host "Reduced management overhead" "INFO"
Write-Host "Environmental efficiency" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


