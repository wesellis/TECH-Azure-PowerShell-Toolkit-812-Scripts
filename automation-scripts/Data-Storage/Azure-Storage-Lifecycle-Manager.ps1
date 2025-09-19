#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToTierCool = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToTierArchive = 90,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToDelete = 365
)

#region Functions

Write-Information "Configuring lifecycle management for: $StorageAccountName"

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

Write-Information " Lifecycle management configured successfully:"
Write-Information "  Storage Account: $StorageAccountName"
Write-Information "  Tier to Cool: After $DaysToTierCool days"
Write-Information "  Tier to Archive: After $DaysToTierArchive days"
Write-Information "  Delete: After $DaysToDelete days"

Write-Information "`nLifecycle Benefits:"
Write-Information "• Automatic cost optimization"
Write-Information "• Compliance with retention policies"
Write-Information "• Reduced management overhead"
Write-Information "• Environmental efficiency"


#endregion
