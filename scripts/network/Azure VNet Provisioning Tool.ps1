#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Azure Vnet Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VnetName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AddressPrefix,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$SubnetName = " default" ,
    [string]$SubnetPrefix
)
Write-Host "Provisioning Virtual Network: $VnetName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Address Prefix: $AddressPrefix"
if ($SubnetPrefix) {
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix
    Write-Host "Subnet: $SubnetName ($SubnetPrefix)"
    # Create virtual network with subnet
   $params = @{
       ResourceGroupName = $ResourceGroupName
       Location = $Location
       AddressPrefix = $AddressPrefix
       Subnet = $SubnetConfig
       ErrorAction = "Stop"
       Name = $VnetName
   }
   ; @params
} else {
    # Create virtual network without subnet
   $params = @{
       ErrorAction = "Stop"
       AddressPrefix = $AddressPrefix
       ResourceGroupName = $ResourceGroupName
       Name = $VnetName
       Location = $Location
   }
   ; @params
}
Write-Host "Virtual Network $VnetName provisioned successfully"
Write-Host "VNet ID: $($VNet.Id)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


