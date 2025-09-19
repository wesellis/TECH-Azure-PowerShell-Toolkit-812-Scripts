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

#region Functions

Write-Information "Creating Route Table: $RouteTableName"

# Create route table
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $RouteTableName
    Location = $Location
}
$RouteTable @params

Write-Information " Route Table created successfully:"
Write-Information "  Name: $($RouteTable.Name)"
Write-Information "  Location: $($RouteTable.Location)"

# Add custom route if parameters provided
if ($RouteName -and $AddressPrefix) {
    Write-Information "`nAdding custom route: $RouteName"
    
    if ($NextHopIpAddress -and $NextHopType -eq "VirtualAppliance") {
        $params = @{
            NextHopIpAddress = $NextHopIpAddress } else { Add-AzRouteConfig
            RouteTable = $RouteTable  Write-Information " Custom route added:" Write-Information "  Route Name: $RouteName" Write-Information "  Address Prefix: $AddressPrefix" Write-Information "  Next Hop Type: $NextHopType" if ($NextHopIpAddress) { Write-Information "  Next Hop IP: $NextHopIpAddress" }
            Name = $RouteName
            NextHopType = $NextHopType }  Set-AzRouteTable
            AddressPrefix = $AddressPrefix
        }
        Add-AzRouteConfig @params
}

Write-Information "`nNext Steps:"
Write-Information "1. Associate route table with subnet(s)"
Write-Information "2. Add additional routes as needed"
Write-Information "3. Test routing behavior"


#endregion
