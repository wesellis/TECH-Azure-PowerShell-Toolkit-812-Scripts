<#
.SYNOPSIS
    Azure Vm Availabilityset Creator

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
    We Enhanced Azure Vm Availabilityset Creator

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



[CmdletBinding()]
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
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]; 
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
    [string]$WEAvailabilitySetName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [int]$WEPlatformFaultDomainCount = 2,
    
    [Parameter(Mandatory=$false)]
    [int]$WEPlatformUpdateDomainCount = 5
)

Write-WELog " Creating Availability Set: $WEAvailabilitySetName" " INFO"
; 
$WEAvailabilitySet = New-AzAvailabilitySet -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEAvailabilitySetName `
    -Location $WELocation `
    -PlatformFaultDomainCount $WEPlatformFaultDomainCount `
    -PlatformUpdateDomainCount $WEPlatformUpdateDomainCount `
    -Sku Aligned

Write-WELog " ✅ Availability Set created successfully:" " INFO"
Write-WELog "  Name: $($WEAvailabilitySet.Name)" " INFO"
Write-WELog "  Location: $($WEAvailabilitySet.Location)" " INFO"
Write-WELog "  Fault Domains: $($WEAvailabilitySet.PlatformFaultDomainCount)" " INFO"
Write-WELog "  Update Domains: $($WEAvailabilitySet.PlatformUpdateDomainCount)" " INFO"
Write-WELog "  SKU: $($WEAvailabilitySet.Sku)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
