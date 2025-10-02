#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$NatGatewayName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [int]$IdleTimeoutInMinutes = 10
)
Write-Output "Creating NAT Gateway: $NatGatewayName"
$NatIpName = "$NatGatewayName-pip"
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
Write-Output "NAT Gateway created successfully:"
Write-Output "Name: $($NatGateway.Name)"
Write-Output "Location: $($NatGateway.Location)"
Write-Output "SKU: $($NatGateway.Sku.Name)"
Write-Output "Idle Timeout: $($NatGateway.IdleTimeoutInMinutes) minutes"
Write-Output "Public IP: $($NatIp.IpAddress)"
Write-Output "`nNext Steps:"
Write-Output "1. Associate NAT Gateway with subnet(s)"
Write-Output "2. Configure route tables if needed"
Write-Output "3. Test outbound connectivity"
Write-Output "`nUsage Command:"
Write-Output "Set-AzVirtualNetworkSubnetConfig -VirtualNetwork `$vnet -Name 'subnet-name' -AddressPrefix '10.0.1.0/24' -NatGateway `$NatGateway"



