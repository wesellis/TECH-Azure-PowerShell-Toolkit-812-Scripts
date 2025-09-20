<#
.SYNOPSIS
    Azure Vm Availabilityset Creator

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
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
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

