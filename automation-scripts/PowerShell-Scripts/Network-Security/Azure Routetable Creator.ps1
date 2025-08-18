<#
.SYNOPSIS
    Azure Routetable Creator

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
    We Enhanced Azure Routetable Creator

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
    [string]$WERouteTableName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERouteName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAddressPrefix,
    
    [Parameter(Mandatory=$false)]
    [string]$WENextHopType = " VirtualAppliance" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WENextHopIpAddress
)

Write-WELog " Creating Route Table: $WERouteTableName" " INFO"

; 
$WERouteTable = New-AzRouteTable `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WERouteTableName `
    -Location $WELocation

Write-WELog " ✅ Route Table created successfully:" " INFO"
Write-WELog "  Name: $($WERouteTable.Name)" " INFO"
Write-WELog "  Location: $($WERouteTable.Location)" " INFO"


if ($WERouteName -and $WEAddressPrefix) {
    Write-WELog " `nAdding custom route: $WERouteName" " INFO"
    
    if ($WENextHopIpAddress -and $WENextHopType -eq " VirtualAppliance" ) {
        Add-AzRouteConfig `
            -RouteTable $WERouteTable `
            -Name $WERouteName `
            -AddressPrefix $WEAddressPrefix `
            -NextHopType $WENextHopType `
            -NextHopIpAddress $WENextHopIpAddress
    } else {
        Add-AzRouteConfig `
            -RouteTable $WERouteTable `
            -Name $WERouteName `
            -AddressPrefix $WEAddressPrefix `
            -NextHopType $WENextHopType
    }
    
    Set-AzRouteTable -RouteTable $WERouteTable
    
    Write-WELog " ✅ Custom route added:" " INFO"
    Write-WELog "  Route Name: $WERouteName" " INFO"
    Write-WELog "  Address Prefix: $WEAddressPrefix" " INFO"
    Write-WELog "  Next Hop Type: $WENextHopType" " INFO"
    if ($WENextHopIpAddress) {
        Write-WELog "  Next Hop IP: $WENextHopIpAddress" " INFO"
    }
}

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Associate route table with subnet(s)" " INFO"
Write-WELog " 2. Add additional routes as needed" " INFO"
Write-WELog " 3. Test routing behavior" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
