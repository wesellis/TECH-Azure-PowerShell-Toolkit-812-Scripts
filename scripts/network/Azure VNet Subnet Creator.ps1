#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Azure Vnet Subnet Creator

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
    [string]$VNetName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubnetName,
    [Parameter(Mandatory)]
    [string]$AddressPrefix
)
Write-Output "Adding subnet to VNet: $VNetName"
    [string]$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    $params = @{
    AddressPrefix = $AddressPrefix
    VirtualNetwork = $VNet
    Name = $SubnetName
}
Add-AzVirtualNetworkSubnetConfig @params
Set-AzVirtualNetwork -VirtualNetwork $VNet
Write-Output "Subnet added successfully:"
Write-Output "Subnet: $SubnetName"
Write-Output "Address: $AddressPrefix"
Write-Output "VNet: $VNetName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
