#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Azure Vnet Provisioning Tool

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
Write-Output "Provisioning Virtual Network: $VnetName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "Address Prefix: $AddressPrefix"
if ($SubnetPrefix) {
    [string]$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix
    Write-Output "Subnet: $SubnetName ($SubnetPrefix)"
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
    $params = @{
       ErrorAction = "Stop"
       AddressPrefix = $AddressPrefix
       ResourceGroupName = $ResourceGroupName
       Name = $VnetName
       Location = $Location
   }
   ; @params
}
Write-Output "Virtual Network $VnetName provisioned successfully"
Write-Output "VNet ID: $($VNet.Id)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
