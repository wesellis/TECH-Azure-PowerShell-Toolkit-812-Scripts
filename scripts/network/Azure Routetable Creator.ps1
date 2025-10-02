#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Routetable Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
;
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$RouteTableName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RouteName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AddressPrefix,
    [Parameter()]
    [string]$NextHopType = "VirtualAppliance" ,
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
    [string]$RouteTable @params
Write-Output "Route Table created successfully:"
Write-Output "Name: $($RouteTable.Name)"
Write-Output "Location: $($RouteTable.Location)"
if ($RouteName -and $AddressPrefix) {
    Write-Output " `nAdding custom route: $RouteName"
    if ($NextHopIpAddress -and $NextHopType -eq "VirtualAppliance" ) {
    $params = @{
            NextHopIpAddress = $NextHopIpAddress } else { Add-AzRouteConfig
            RouteTable = $RouteTable  Write-Output "Custom route added:" "INFO"Write-Output "Route Name: $RouteName" "INFO"Write-Output "Address Prefix: $AddressPrefix" "INFO"Write-Output "Next Hop Type: $NextHopType" "INFO" if ($NextHopIpAddress) { Write-Output "Next Hop IP: $NextHopIpAddress" }
            Name = $RouteName
            NextHopType = $NextHopType }  Set-AzRouteTable
            AddressPrefix = $AddressPrefix
        }
        Add-AzRouteConfig @params
}
Write-Output " `nNext Steps:"
Write-Output " 1. Associate route table with subnet(s)"
Write-Output " 2. Add additional routes as needed"
Write-Output " 3. Test routing behavior"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
