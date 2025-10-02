#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Route Tables

.DESCRIPTION
    Manage Route Tables
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
Write-Output "Creating Route Table: $RouteTableName"
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $RouteTableName
    Location = $Location
}
$RouteTable @params
Write-Output "Route Table created successfully:"
Write-Output "Name: $($RouteTable.Name)"
Write-Output "Location: $($RouteTable.Location)"
if ($RouteName -and $AddressPrefix) {
    Write-Output "`nAdding custom route: $RouteName"
    if ($NextHopIpAddress -and $NextHopType -eq "VirtualAppliance") {
        $params = @{
            NextHopIpAddress = $NextHopIpAddress } else { Add-AzRouteConfig
            RouteTable = $RouteTable  Write-Output "Custom route added:" Write-Output "Route Name: $RouteName"Write-Output "Address Prefix: $AddressPrefix"Write-Output "Next Hop Type: $NextHopType" if ($NextHopIpAddress) { Write-Output "Next Hop IP: $NextHopIpAddress" }
            Name = $RouteName
            NextHopType = $NextHopType }  Set-AzRouteTable
            AddressPrefix = $AddressPrefix
        }
        Add-AzRouteConfig @params
}
Write-Output "`nNext Steps:"
Write-Output "1. Associate route table with subnet(s)"
Write-Output "2. Add additional routes as needed"
Write-Output "3. Test routing behavior"



