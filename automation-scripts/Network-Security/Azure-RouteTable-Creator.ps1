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

Write-Information "Creating Route Table: $RouteTableName"

# Create route table
$RouteTable = New-AzRouteTable -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $RouteTableName `
    -Location $Location

Write-Information "✅ Route Table created successfully:"
Write-Information "  Name: $($RouteTable.Name)"
Write-Information "  Location: $($RouteTable.Location)"

# Add custom route if parameters provided
if ($RouteName -and $AddressPrefix) {
    Write-Information "`nAdding custom route: $RouteName"
    
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
    
    Write-Information "✅ Custom route added:"
    Write-Information "  Route Name: $RouteName"
    Write-Information "  Address Prefix: $AddressPrefix"
    Write-Information "  Next Hop Type: $NextHopType"
    if ($NextHopIpAddress) {
        Write-Information "  Next Hop IP: $NextHopIpAddress"
    }
}

Write-Information "`nNext Steps:"
Write-Information "1. Associate route table with subnet(s)"
Write-Information "2. Add additional routes as needed"
Write-Information "3. Test routing behavior"
