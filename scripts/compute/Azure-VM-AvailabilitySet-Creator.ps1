#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$AvailabilitySetName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [int]$PlatformFaultDomainCount = 2,
    [Parameter()]
    [int]$PlatformUpdateDomainCount = 5
)
Write-Output "Creating Availability Set: $AvailabilitySetName"
$params = @{
    ResourceGroupName = $ResourceGroupName
    PlatformUpdateDomainCount = $PlatformUpdateDomainCount
    Location = $Location
    PlatformFaultDomainCount = $PlatformFaultDomainCount
    Sku = "Aligned"
    ErrorAction = "Stop"
    Name = $AvailabilitySetName
}
$AvailabilitySet = New-AzAvailabilitySet @params
Write-Output "Availability Set created successfully:"
Write-Output "Name: $($AvailabilitySet.Name)"
Write-Output "Location: $($AvailabilitySet.Location)"
Write-Output "Fault Domains: $($AvailabilitySet.PlatformFaultDomainCount)"
Write-Output "Update Domains: $($AvailabilitySet.PlatformUpdateDomainCount)"
Write-Output "SKU: $($AvailabilitySet.Sku)"



