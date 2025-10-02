#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Loadbalancer Manager

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
;
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    $BalancerName
)
    $LoadBalancer = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $BalancerName
Write-Output "Load Balancer: $($LoadBalancer.Name)"
Write-Output "Resource Group: $($LoadBalancer.ResourceGroupName)"
Write-Output "Location: $($LoadBalancer.Location)"
Write-Output "Provisioning State: $($LoadBalancer.ProvisioningState)"
Write-Output "Frontend IP Configurations: $($LoadBalancer.FrontendIpConfigurations.Count)"
Write-Output "Backend Address Pools: $($LoadBalancer.BackendAddressPools.Count)"
Write-Output "Load Balancing Rules: $($LoadBalancer.LoadBalancingRules.Count)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
