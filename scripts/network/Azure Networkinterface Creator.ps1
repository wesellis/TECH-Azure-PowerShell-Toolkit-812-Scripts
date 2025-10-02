#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Networkinterface Creator

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
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$NicName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubnetId,
    [Parameter()]
    [string]$PublicIpId
)
Write-Output "Creating Network Interface: $NicName"
if ($PublicIpId) {
    $params = @{
       ResourceGroupName = $ResourceGroupName
       Location = $Location
       PublicIpAddressId = $PublicIpId
       SubnetId = $SubnetId
       ErrorAction = "Stop"
       Name = $NicName
   }
   ; @params
} else {
    $params = @{
       ErrorAction = "Stop"
       SubnetId = $SubnetId
       ResourceGroupName = $ResourceGroupName
       Name = $NicName
       Location = $Location
   }
   ; @params
}
Write-Output "Network Interface created successfully:"
Write-Output "Name: $($Nic.Name)"
Write-Output "Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
Write-Output "Location: $($Nic.Location)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
