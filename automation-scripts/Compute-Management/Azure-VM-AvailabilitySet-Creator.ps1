#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AvailabilitySetName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [int]$PlatformFaultDomainCount = 2,
    
    [Parameter(Mandatory=$false)]
    [int]$PlatformUpdateDomainCount = 5
)

#region Functions

Write-Information "Creating Availability Set: $AvailabilitySetName"

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

Write-Information " Availability Set created successfully:"
Write-Information "  Name: $($AvailabilitySet.Name)"
Write-Information "  Location: $($AvailabilitySet.Location)"
Write-Information "  Fault Domains: $($AvailabilitySet.PlatformFaultDomainCount)"
Write-Information "  Update Domains: $($AvailabilitySet.PlatformUpdateDomainCount)"
Write-Information "  SKU: $($AvailabilitySet.Sku)"


#endregion
