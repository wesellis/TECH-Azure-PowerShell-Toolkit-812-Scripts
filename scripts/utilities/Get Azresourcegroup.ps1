#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get resourcegroup

.DESCRIPTION
    Get resourcegroup operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ResourceGroupName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

if ($ResourceGroupName) {
    Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop | Select-Object -Property ResourceGroupName, Location, ProvisioningState, Tags
} else {
    Get-AzResourceGroup -ErrorAction Stop | Select-Object -Property ResourceGroupName, Location, ProvisioningState, Tags
}