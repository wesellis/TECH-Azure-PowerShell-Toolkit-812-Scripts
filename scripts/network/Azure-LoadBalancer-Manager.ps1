#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Load Balancer

.DESCRIPTION
    Manage Load Balancer
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$BalancerName
)
$LoadBalancer = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $BalancerName
Write-Output "Load Balancer: $($LoadBalancer.Name)"
Write-Output "Resource Group: $($LoadBalancer.ResourceGroupName)"
Write-Output "Location: $($LoadBalancer.Location)"
Write-Output "Provisioning State: $($LoadBalancer.ProvisioningState)"
Write-Output "Frontend IP Configurations: $($LoadBalancer.FrontendIpConfigurations.Count)"
Write-Output "Backend Address Pools: $($LoadBalancer.BackendAddressPools.Count)"
Write-Output "Load Balancing Rules: $($LoadBalancer.LoadBalancingRules.Count)"



