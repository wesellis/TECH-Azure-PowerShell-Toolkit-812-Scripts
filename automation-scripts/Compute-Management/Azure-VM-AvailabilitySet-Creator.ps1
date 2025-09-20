<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
#>
param (
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
Write-Host "Creating Availability Set: $AvailabilitySetName"
$params = @{
    ResourceGroupName = $ResourceGroupName
    PlatformUpdateDomainCount = $PlatformUpdateDomainCount
    Location = $Location
    PlatformFaultDomainCount = $PlatformFaultDomainCount
    Sku = "Aligned"
    ErrorAction = "Stop"
    Name = $AvailabilitySetName
}
$AvailabilitySet @params
Write-Host "Availability Set created successfully:"
Write-Host "Name: $($AvailabilitySet.Name)"
Write-Host "Location: $($AvailabilitySet.Location)"
Write-Host "Fault Domains: $($AvailabilitySet.PlatformFaultDomainCount)"
Write-Host "Update Domains: $($AvailabilitySet.PlatformUpdateDomainCount)"
Write-Host "SKU: $($AvailabilitySet.Sku)"

