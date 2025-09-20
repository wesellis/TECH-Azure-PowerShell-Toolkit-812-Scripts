<#
.SYNOPSIS
    Azure Networkinterface Creator

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
Write-Host "Creating Network Interface: $NicName"
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
Write-Host "Network Interface created successfully:"
Write-Host "Name: $($Nic.Name)"
Write-Host "Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
Write-Host "Location: $($Nic.Location)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

