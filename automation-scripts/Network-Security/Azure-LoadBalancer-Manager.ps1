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
    [string]$ResourceGroupName,
    [string]$BalancerName
)

#region Functions

# Get load balancer details
$LoadBalancer = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $BalancerName

Write-Information "Load Balancer: $($LoadBalancer.Name)"
Write-Information "Resource Group: $($LoadBalancer.ResourceGroupName)"
Write-Information "Location: $($LoadBalancer.Location)"
Write-Information "Provisioning State: $($LoadBalancer.ProvisioningState)"
Write-Information "Frontend IP Configurations: $($LoadBalancer.FrontendIpConfigurations.Count)"
Write-Information "Backend Address Pools: $($LoadBalancer.BackendAddressPools.Count)"
Write-Information "Load Balancing Rules: $($LoadBalancer.LoadBalancingRules.Count)"


#endregion
