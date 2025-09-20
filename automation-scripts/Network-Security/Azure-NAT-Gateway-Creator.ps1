#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$NatGatewayName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [int]$IdleTimeoutInMinutes = 10
)
Write-Host "Creating NAT Gateway: $NatGatewayName"
# Create public IP for NAT Gateway
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
# Create NAT Gateway
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
Write-Host "`nNext Steps:"
Write-Host "1. Associate NAT Gateway with subnet(s)"
Write-Host "2. Configure route tables if needed"
Write-Host "3. Test outbound connectivity"
Write-Host "`nUsage Command:"
Write-Host "Set-AzVirtualNetworkSubnetConfig -VirtualNetwork `$vnet -Name 'subnet-name' -AddressPrefix '10.0.1.0/24' -NatGateway `$natGateway"

