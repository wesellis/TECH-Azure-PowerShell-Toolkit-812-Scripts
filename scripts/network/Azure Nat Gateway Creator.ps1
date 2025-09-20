#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Nat Gateway Creator

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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$NatGatewayName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [int]$IdleTimeoutInMinutes = 10
)
Write-Host "Creating NAT Gateway: $NatGatewayName"
$NatIpName = " $NatGatewayName-pip";
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $NatIpName
}
$NatIp @params
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    PublicIpAddress = $NatIp
    IdleTimeoutInMinutes = $IdleTimeoutInMinutes
    ErrorAction = "Stop"
    Name = $NatGatewayName
}
$NatGateway @params
Write-Host "NAT Gateway created successfully:"
Write-Host "Name: $($NatGateway.Name)"
Write-Host "Location: $($NatGateway.Location)"
Write-Host "SKU: $($NatGateway.Sku.Name)"
Write-Host "Idle Timeout: $($NatGateway.IdleTimeoutInMinutes) minutes"
Write-Host "Public IP: $($NatIp.IpAddress)"
Write-Host " `nNext Steps:"
Write-Host " 1. Associate NAT Gateway with subnet(s)"
Write-Host " 2. Configure route tables if needed"
Write-Host " 3. Test outbound connectivity"
Write-Host " `nUsage Command:"
Write-Host "Set-AzVirtualNetworkSubnetConfig -VirtualNetwork `$vnet -Name 'subnet-name' -AddressPrefix '10.0.1.0/24' -NatGateway `$natGateway"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


