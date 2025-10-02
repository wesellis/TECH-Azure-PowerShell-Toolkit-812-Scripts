#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    New Azpublicipaddress

.DESCRIPTION
    Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName = "FGC_Prod_Bastion_RG",

    [Parameter(Mandatory = $true)]
    [string]$Name = "FGC_Prod_Bastion_PublicIP",

    [Parameter(Mandatory = $true)]
    [string]$Location = "canadacentral",

    [Parameter()]
    [string]$AllocationMethod = 'Static',

    [Parameter()]
    [string]$Sku = 'Standard'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$NewAzPublicIpAddressSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Name
    Location = $Location
    AllocationMethod = $AllocationMethod
    Sku = $Sku
}
$publicip = New-AzPublicIpAddress -ErrorAction Stop @NewAzPublicIpAddressSplat
$publicip