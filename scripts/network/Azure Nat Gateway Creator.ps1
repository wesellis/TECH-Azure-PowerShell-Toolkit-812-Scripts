#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Nat Gateway Creator

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
    [string]$NatGatewayName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [int]$IdleTimeoutInMinutes = 10
)
Write-Output "Creating NAT Gateway: $NatGatewayName"
    [string]$NatIpName = " $NatGatewayName-pip";
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $NatIpName
}
    [string]$NatIp @params
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    PublicIpAddress = $NatIp
    IdleTimeoutInMinutes = $IdleTimeoutInMinutes
    ErrorAction = "Stop"
    Name = $NatGatewayName
}
    [string]$NatGateway @params
Write-Output "NAT Gateway created successfully:"
Write-Output "Name: $($NatGateway.Name)"
Write-Output "Location: $($NatGateway.Location)"
Write-Output "SKU: $($NatGateway.Sku.Name)"
Write-Output "Idle Timeout: $($NatGateway.IdleTimeoutInMinutes) minutes"
Write-Output "Public IP: $($NatIp.IpAddress)"
Write-Output " `nNext Steps:"
Write-Output " 1. Associate NAT Gateway with subnet(s)"
Write-Output " 2. Configure route tables if needed"
Write-Output " 3. Test outbound connectivity"
Write-Output " `nUsage Command:"
Write-Output "Set-AzVirtualNetworkSubnetConfig -VirtualNetwork `$vnet -Name 'subnet-name' -AddressPrefix '10.0.1.0/24' -NatGateway `$NatGateway"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
