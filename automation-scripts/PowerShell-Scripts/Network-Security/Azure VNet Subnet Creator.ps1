<#
.SYNOPSIS
    Azure Vnet Subnet Creator

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
    [string]$VNetName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubnetName,
    [Parameter(Mandatory)]
    [string]$AddressPrefix
)
Write-Host "Adding subnet to VNet: $VNetName"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$params = @{
    AddressPrefix = $AddressPrefix
    VirtualNetwork = $VNet
    Name = $SubnetName
}
Add-AzVirtualNetworkSubnetConfig @params
Set-AzVirtualNetwork -VirtualNetwork $VNet
Write-Host "Subnet added successfully:"
Write-Host "Subnet: $SubnetName"
Write-Host "Address: $AddressPrefix"
Write-Host "VNet: $VNetName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

