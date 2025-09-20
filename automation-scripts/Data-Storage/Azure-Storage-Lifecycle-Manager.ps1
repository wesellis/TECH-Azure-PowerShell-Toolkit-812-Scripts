<#
.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)#>
param (
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
Write-Host "Configuring lifecycle management for: $StorageAccountName"
# Create lifecycle policy rule
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
# Convert to JSON
$PolicyJson = $LifecycleRule | ConvertTo-Json -Depth 10
# Apply lifecycle policy
$params = @{
    ErrorAction = "Stop"
    Policy = $PolicyJson
    ResourceGroupName = $ResourceGroupName
    StorageAccountName = $StorageAccountName
}
Set-AzStorageAccountManagementPolicy @params
Write-Host "Lifecycle management configured successfully:"
Write-Host "Storage Account: $StorageAccountName"
Write-Host "Tier to Cool: After $DaysToTierCool days"
Write-Host "Tier to Archive: After $DaysToTierArchive days"
Write-Host "Delete: After $DaysToDelete days"
Write-Host "`nLifecycle Benefits:"
Write-Host "Automatic cost optimization"
Write-Host "Compliance with retention policies"
Write-Host "Reduced management overhead"
Write-Host "Environmental efficiency"

