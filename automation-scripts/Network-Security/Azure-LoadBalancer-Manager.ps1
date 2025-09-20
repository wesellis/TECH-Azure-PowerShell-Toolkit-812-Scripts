<#
.SYNOPSIS
    Manage Load Balancer

.DESCRIPTION
    Manage Load Balancer
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [string]$ResourceGroupName,
    [string]$BalancerName
)
# Get load balancer details
$LoadBalancer = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $BalancerName
Write-Host "Load Balancer: $($LoadBalancer.Name)"
Write-Host "Resource Group: $($LoadBalancer.ResourceGroupName)"
Write-Host "Location: $($LoadBalancer.Location)"
Write-Host "Provisioning State: $($LoadBalancer.ProvisioningState)"
Write-Host "Frontend IP Configurations: $($LoadBalancer.FrontendIpConfigurations.Count)"
Write-Host "Backend Address Pools: $($LoadBalancer.BackendAddressPools.Count)"
Write-Host "Load Balancing Rules: $($LoadBalancer.LoadBalancingRules.Count)"

