#Requires -Version 7.4
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Create Azure public IP address

.DESCRIPTION
    Create Azure public IP address operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter()]
    [ValidateSet('Static', 'Dynamic')]
    [string]$AllocationMethod = 'Static',

    [Parameter()]
    [ValidateSet('Basic', 'Standard')]
    [string]$Sku = 'Standard',

    [Parameter()]
    [ValidateSet('IPv4', 'IPv6')]
    [string]$IpAddressVersion = 'IPv4',

    [Parameter()]
    [hashtable]$Tags
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    $newAzPublicIpAddressSplat = @{
        Name = $Name
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        AllocationMethod = $AllocationMethod
        Sku = $Sku
        IpAddressVersion = $IpAddressVersion
    }

    if ($Tags) {
        $newAzPublicIpAddressSplat.Tag = $Tags
    }

    $publicIPConfig = New-AzPublicIpAddress @newAzPublicIpAddressSplat -ErrorAction Stop
    return $publicIPConfig
}
catch {
    Write-Error "Failed to create public IP address: $($_.Exception.Message)"
    throw
}