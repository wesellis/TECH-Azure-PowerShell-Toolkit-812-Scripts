# ============================================================================
# Script Name: Azure Load Balancer Management Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Manages Azure Load Balancer configurations and monitoring
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$BalancerName
)

# Get load balancer details
$LoadBalancer = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $BalancerName

Write-Information "Load Balancer: $($LoadBalancer.Name)"
Write-Information "Resource Group: $($LoadBalancer.ResourceGroupName)"
Write-Information "Location: $($LoadBalancer.Location)"
Write-Information "Provisioning State: $($LoadBalancer.ProvisioningState)"
Write-Information "Frontend IP Configurations: $($LoadBalancer.FrontendIpConfigurations.Count)"
Write-Information "Backend Address Pools: $($LoadBalancer.BackendAddressPools.Count)"
Write-Information "Load Balancing Rules: $($LoadBalancer.LoadBalancingRules.Count)"
