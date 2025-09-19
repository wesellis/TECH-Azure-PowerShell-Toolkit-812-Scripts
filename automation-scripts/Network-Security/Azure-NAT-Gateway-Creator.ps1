#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$NatGatewayName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [int]$IdleTimeoutInMinutes = 10
)

#region Functions

Write-Information "Creating NAT Gateway: $NatGatewayName"

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

Write-Information " NAT Gateway created successfully:"
Write-Information "  Name: $($NatGateway.Name)"
Write-Information "  Location: $($NatGateway.Location)"
Write-Information "  SKU: $($NatGateway.Sku.Name)"
Write-Information "  Idle Timeout: $($NatGateway.IdleTimeoutInMinutes) minutes"
Write-Information "  Public IP: $($NatIp.IpAddress)"

Write-Information "`nNext Steps:"
Write-Information "1. Associate NAT Gateway with subnet(s)"
Write-Information "2. Configure route tables if needed"
Write-Information "3. Test outbound connectivity"

Write-Information "`nUsage Command:"
Write-Information "Set-AzVirtualNetworkSubnetConfig -VirtualNetwork `$vnet -Name 'subnet-name' -AddressPrefix '10.0.1.0/24' -NatGateway `$natGateway"


#endregion
