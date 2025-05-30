# ============================================================================
# Script Name: Azure Route Table Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Route Tables and custom routes for traffic control
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$RouteTableName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$RouteName,
    
    [Parameter(Mandatory=$false)]
    [string]$AddressPrefix,
    
    [Parameter(Mandatory=$false)]
    [string]$NextHopType = "VirtualAppliance",
    
    [Parameter(Mandatory=$false)]
    [string]$NextHopIpAddress
)

Write-Host "Creating Route Table: $RouteTableName"

# Create route table
$RouteTable = New-AzRouteTable `
    -ResourceGroupName $ResourceGroupName `
    -Name $RouteTableName `
    -Location $Location

Write-Host "✅ Route Table created successfully:"
Write-Host "  Name: $($RouteTable.Name)"
Write-Host "  Location: $($RouteTable.Location)"

# Add custom route if parameters provided
if ($RouteName -and $AddressPrefix) {
    Write-Host "`nAdding custom route: $RouteName"
    
    if ($NextHopIpAddress -and $NextHopType -eq "VirtualAppliance") {
        Add-AzRouteConfig `
            -RouteTable $RouteTable `
            -Name $RouteName `
            -AddressPrefix $AddressPrefix `
            -NextHopType $NextHopType `
            -NextHopIpAddress $NextHopIpAddress
    } else {
        Add-AzRouteConfig `
            -RouteTable $RouteTable `
            -Name $RouteName `
            -AddressPrefix $AddressPrefix `
            -NextHopType $NextHopType
    }
    
    Set-AzRouteTable -RouteTable $RouteTable
    
    Write-Host "✅ Custom route added:"
    Write-Host "  Route Name: $RouteName"
    Write-Host "  Address Prefix: $AddressPrefix"
    Write-Host "  Next Hop Type: $NextHopType"
    if ($NextHopIpAddress) {
        Write-Host "  Next Hop IP: $NextHopIpAddress"
    }
}

Write-Host "`nNext Steps:"
Write-Host "1. Associate route table with subnet(s)"
Write-Host "2. Add additional routes as needed"
Write-Host "3. Test routing behavior"
