#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$StorageAccountName,
    [Parameter()]
    [int]$DaysToTierCool = 30,
    [Parameter()]
    [int]$DaysToTierArchive = 90,
    [Parameter()]
    [int]$DaysToDelete = 365
)
Write-Output "Configuring lifecycle management for: $StorageAccountName"
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
Write-Output "Lifecycle management configured successfully:"
Write-Output "Storage Account: $StorageAccountName"
Write-Output "Tier to Cool: After $DaysToTierCool days"
Write-Output "Tier to Archive: After $DaysToTierArchive days"
Write-Output "Delete: After $DaysToDelete days"
Write-Output "`nLifecycle Benefits:"
Write-Output "Automatic cost optimization"
Write-Output "Compliance with retention policies"
Write-Output "Reduced management overhead"
Write-Output "Environmental efficiency"



