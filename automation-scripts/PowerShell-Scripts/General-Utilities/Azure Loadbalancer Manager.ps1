<#
.SYNOPSIS
    Azure Loadbalancer Manager

.DESCRIPTION
    Azure automation
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
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$BalancerName
)
$LoadBalancer = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $BalancerName
Write-Host "Load Balancer: $($LoadBalancer.Name)"
Write-Host "Resource Group: $($LoadBalancer.ResourceGroupName)"
Write-Host "Location: $($LoadBalancer.Location)"
Write-Host "Provisioning State: $($LoadBalancer.ProvisioningState)"
Write-Host "Frontend IP Configurations: $($LoadBalancer.FrontendIpConfigurations.Count)"
Write-Host "Backend Address Pools: $($LoadBalancer.BackendAddressPools.Count)"
Write-Host "Load Balancing Rules: $($LoadBalancer.LoadBalancingRules.Count)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

