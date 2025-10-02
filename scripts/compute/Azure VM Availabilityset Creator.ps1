#Requires -Version 7.4
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Availabilityset Creator

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
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
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
    [string]$AvailabilitySetName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
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
    [string]$AvailabilitySet @params
Write-Output "Availability Set created successfully:"
Write-Output "Name: $($AvailabilitySet.Name)"
Write-Output "Location: $($AvailabilitySet.Location)"
Write-Output "Fault Domains: $($AvailabilitySet.PlatformFaultDomainCount)"
Write-Output "Update Domains: $($AvailabilitySet.PlatformUpdateDomainCount)"
Write-Output "SKU: $($AvailabilitySet.Sku)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
