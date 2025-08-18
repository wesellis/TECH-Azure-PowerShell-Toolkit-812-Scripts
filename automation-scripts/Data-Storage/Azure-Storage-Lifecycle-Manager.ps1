# ============================================================================
# Script Name: Azure Storage Account Lifecycle Manager
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Configures lifecycle management policies for Azure Storage Account
# ============================================================================

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
Set-AzStorageAccountManagementPolicy -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -Policy $PolicyJson

Write-Information "✅ Lifecycle management configured successfully:"
Write-Information "  Storage Account: $StorageAccountName"
Write-Information "  Tier to Cool: After $DaysToTierCool days"
Write-Information "  Tier to Archive: After $DaysToTierArchive days"
Write-Information "  Delete: After $DaysToDelete days"

Write-Information "`nLifecycle Benefits:"
Write-Information "• Automatic cost optimization"
Write-Information "• Compliance with retention policies"
Write-Information "• Reduced management overhead"
Write-Information "• Environmental efficiency"
