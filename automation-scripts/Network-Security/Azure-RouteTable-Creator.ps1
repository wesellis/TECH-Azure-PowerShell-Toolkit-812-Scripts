<#
.SYNOPSIS
    Manage Route Tables

.DESCRIPTION
    Manage Route Tables
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$RouteTableName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [string]$RouteName,
    [Parameter()]
    [string]$AddressPrefix,
    [Parameter()]
    [string]$NextHopType = "VirtualAppliance",
    [Parameter()]
    [string]$NextHopIpAddress
)
Write-Host "Creating Route Table: $RouteTableName"
# Create route table
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $RouteTableName
    Location = $Location
}
$RouteTable @params
Write-Host "Route Table created successfully:"
Write-Host "Name: $($RouteTable.Name)"
Write-Host "Location: $($RouteTable.Location)"
# Add custom route if parameters provided
if ($RouteName -and $AddressPrefix) {
    Write-Host "`nAdding custom route: $RouteName"
    if ($NextHopIpAddress -and $NextHopType -eq "VirtualAppliance") {
        $params = @{
            NextHopIpAddress = $NextHopIpAddress } else { Add-AzRouteConfig
            RouteTable = $RouteTable  Write-Host "Custom route added:" Write-Host "Route Name: $RouteName"Write-Host "Address Prefix: $AddressPrefix"Write-Host "Next Hop Type: $NextHopType" if ($NextHopIpAddress) { Write-Host "Next Hop IP: $NextHopIpAddress" }
            Name = $RouteName
            NextHopType = $NextHopType }  Set-AzRouteTable
            AddressPrefix = $AddressPrefix
        }
        Add-AzRouteConfig @params
}
Write-Host "`nNext Steps:"
Write-Host "1. Associate route table with subnet(s)"
Write-Host "2. Add additional routes as needed"
Write-Host "3. Test routing behavior"

