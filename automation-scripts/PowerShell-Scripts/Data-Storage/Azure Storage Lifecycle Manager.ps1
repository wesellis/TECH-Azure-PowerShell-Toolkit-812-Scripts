<#
.SYNOPSIS
    Azure Storage Lifecycle Manager

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Storage Lifecycle Manager

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEStorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDaysToTierCool = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDaysToTierArchive = 90,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDaysToDelete = 365
)

Write-WELog " Configuring lifecycle management for: $WEStorageAccountName" " INFO"

; 
$WELifecycleRule = @{
    enabled = $true
    name = " DefaultLifecycleRule"
    type = " Lifecycle"
    definition = @{
        filters = @{
            blobTypes = @(" blockBlob" )
        }
        actions = @{
            baseBlob = @{
                tierToCool = @{
                    daysAfterModificationGreaterThan = $WEDaysToTierCool
                }
                tierToArchive = @{
                    daysAfterModificationGreaterThan = $WEDaysToTierArchive
                }
                delete = @{
                    daysAfterModificationGreaterThan = $WEDaysToDelete
                }
            }
        }
    }
}

; 
$WEPolicyJson = $WELifecycleRule | ConvertTo-Json -Depth 10


Set-AzStorageAccountManagementPolicy `
    -ResourceGroupName $WEResourceGroupName `
    -StorageAccountName $WEStorageAccountName `
    -Policy $WEPolicyJson

Write-WELog " ✅ Lifecycle management configured successfully:" " INFO"
Write-WELog "  Storage Account: $WEStorageAccountName" " INFO"
Write-WELog "  Tier to Cool: After $WEDaysToTierCool days" " INFO"
Write-WELog "  Tier to Archive: After $WEDaysToTierArchive days" " INFO"
Write-WELog "  Delete: After $WEDaysToDelete days" " INFO"

Write-WELog " `nLifecycle Benefits:" " INFO"
Write-WELog " • Automatic cost optimization" " INFO"
Write-WELog " • Compliance with retention policies" " INFO"
Write-WELog " • Reduced management overhead" " INFO"
Write-WELog " • Environmental efficiency" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
