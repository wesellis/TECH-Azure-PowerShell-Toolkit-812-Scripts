#Requires -Version 7.4
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Invoke Azure Public IP Address creation

.DESCRIPTION
    Creates a new Azure Public IP Address with specified configuration

.PARAMETER PublicIPAddressName
    Name of the public IP address

.PARAMETER DNSNameLabel
    DNS name label for the public IP

.PARAMETER ResourceGroupName
    Name of the resource group

.PARAMETER LocationName
    Azure location name

.PARAMETER Tags
    Hash table of tags to apply

.EXAMPLE
    Invoke-AzPublicIpAddress -PublicIPAddressName "MyPIP" -DNSNameLabel "mydns" -ResourceGroupName "MyRG" -LocationName "East US"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PublicIPAddressName,

    [Parameter(Mandatory = $true)]
    [string]$DNSNameLabel,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$LocationName,

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{}
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Invoke-AzPublicIpAddress {
    $NewAzPublicIpAddressSplat = @{
        Name              = $PublicIPAddressName
        DomainNameLabel   = $DNSNameLabel
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        AllocationMethod  = 'Static'
        Tag               = $Tags
    }
    $PIP = New-AzPublicIpAddress -ErrorAction Stop @NewAzPublicIpAddressSplat
    return $PIP
}

# Execute the function
Invoke-AzPublicIpAddress
