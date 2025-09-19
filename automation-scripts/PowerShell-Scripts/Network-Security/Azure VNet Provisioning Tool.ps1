#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Vnet Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Vnet Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVnetName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAddressPrefix,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [string]$WESubnetName = " default" ,
    [string]$WESubnetPrefix
)

#region Functions

Write-WELog " Provisioning Virtual Network: $WEVnetName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " Address Prefix: $WEAddressPrefix" " INFO"


if ($WESubnetPrefix) {
    $WESubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $WESubnetName -AddressPrefix $WESubnetPrefix
    Write-WELog " Subnet: $WESubnetName ($WESubnetPrefix)" " INFO"
    
    # Create virtual network with subnet
   $params = @{
       ResourceGroupName = $WEResourceGroupName
       Location = $WELocation
       AddressPrefix = $WEAddressPrefix
       Subnet = $WESubnetConfig
       ErrorAction = "Stop"
       Name = $WEVnetName
   }
   ; @params
} else {
    # Create virtual network without subnet
   $params = @{
       ErrorAction = "Stop"
       AddressPrefix = $WEAddressPrefix
       ResourceGroupName = $WEResourceGroupName
       Name = $WEVnetName
       Location = $WELocation
   }
   ; @params
}

Write-WELog " Virtual Network $WEVnetName provisioned successfully" " INFO"
Write-WELog " VNet ID: $($WEVNet.Id)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
