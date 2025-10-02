#Requires -Version 7.4
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Get public IP address

.DESCRIPTION
    Get Azure public IP address information

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$Name
)

$ErrorActionPreference = 'Stop'

if ($Name -and $ResourceGroupName) {
    Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $Name
}
elseif ($ResourceGroupName) {
    Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName
}
else {
    Get-AzPublicIpAddress
}