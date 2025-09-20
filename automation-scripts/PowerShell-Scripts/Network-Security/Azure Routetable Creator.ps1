#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Routetable Creator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
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
Write-Host "Creating Route Table: $RouteTableName"
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
if ($RouteName -and $AddressPrefix) {
    Write-Host " `nAdding custom route: $RouteName"
    if ($NextHopIpAddress -and $NextHopType -eq "VirtualAppliance" ) {
        $params = @{
            NextHopIpAddress = $NextHopIpAddress } else { Add-AzRouteConfig
            RouteTable = $RouteTable  Write-Host "Custom route added:" "INFO"Write-Host "Route Name: $RouteName" "INFO"Write-Host "Address Prefix: $AddressPrefix" "INFO"Write-Host "Next Hop Type: $NextHopType" "INFO" if ($NextHopIpAddress) { Write-Host "Next Hop IP: $NextHopIpAddress" }
            Name = $RouteName
            NextHopType = $NextHopType }  Set-AzRouteTable
            AddressPrefix = $AddressPrefix
        }
        Add-AzRouteConfig @params
}
Write-Host " `nNext Steps:"
Write-Host " 1. Associate route table with subnet(s)"
Write-Host " 2. Add additional routes as needed"
Write-Host " 3. Test routing behavior"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

