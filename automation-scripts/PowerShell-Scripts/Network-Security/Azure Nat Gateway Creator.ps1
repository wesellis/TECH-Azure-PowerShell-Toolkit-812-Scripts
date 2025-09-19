#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Nat Gateway Creator

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
    We Enhanced Azure Nat Gateway Creator

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
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WENatGatewayName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [int]$WEIdleTimeoutInMinutes = 10
)

#region Functions

Write-WELog " Creating NAT Gateway: $WENatGatewayName" " INFO"


$WENatIpName = " $WENatGatewayName-pip"; 
$params = @{
    ResourceGroupName = $WEResourceGroupName
    Sku = "Standard"
    Location = $WELocation
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $WENatIpName
}
$WENatIp @params

; 
$params = @{
    ResourceGroupName = $WEResourceGroupName
    Sku = "Standard"
    Location = $WELocation
    PublicIpAddress = $WENatIp
    IdleTimeoutInMinutes = $WEIdleTimeoutInMinutes
    ErrorAction = "Stop"
    Name = $WENatGatewayName
}
$WENatGateway @params

Write-WELog "  NAT Gateway created successfully:" " INFO"
Write-WELog "  Name: $($WENatGateway.Name)" " INFO"
Write-WELog "  Location: $($WENatGateway.Location)" " INFO"
Write-WELog "  SKU: $($WENatGateway.Sku.Name)" " INFO"
Write-WELog "  Idle Timeout: $($WENatGateway.IdleTimeoutInMinutes) minutes" " INFO"
Write-WELog "  Public IP: $($WENatIp.IpAddress)" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Associate NAT Gateway with subnet(s)" " INFO"
Write-WELog " 2. Configure route tables if needed" " INFO"
Write-WELog " 3. Test outbound connectivity" " INFO"

Write-WELog " `nUsage Command:" " INFO"
Write-WELog " Set-AzVirtualNetworkSubnetConfig -VirtualNetwork `$vnet -Name 'subnet-name' -AddressPrefix '10.0.1.0/24' -NatGateway `$natGateway" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
