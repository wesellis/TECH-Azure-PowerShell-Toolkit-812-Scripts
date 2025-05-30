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
Set-AzStorageAccountManagementPolicy `
    -ResourceGroupName $ResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -Policy $PolicyJson

Write-Host "✅ Lifecycle management configured successfully:"
Write-Host "  Storage Account: $StorageAccountName"
Write-Host "  Tier to Cool: After $DaysToTierCool days"
Write-Host "  Tier to Archive: After $DaysToTierArchive days"
Write-Host "  Delete: After $DaysToDelete days"

Write-Host "`nLifecycle Benefits:"
Write-Host "• Automatic cost optimization"
Write-Host "• Compliance with retention policies"
Write-Host "• Reduced management overhead"
Write-Host "• Environmental efficiency"
