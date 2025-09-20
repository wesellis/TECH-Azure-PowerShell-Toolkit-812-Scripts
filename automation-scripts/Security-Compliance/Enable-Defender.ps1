#Requires -Version 7.0
#Requires -Modules Az.Security

<#
.SYNOPSIS
    Enable Defender

.DESCRIPTION
Enable Azure Defender plans
.PARAMETER Plan
Defender plan to enable (VirtualMachines, SqlServers, etc)
.PARAMETER All
Enable all standard plans
.\Enable-Defender.ps1 -All
.\Enable-Defender.ps1 -Plan VirtualMachines
#>
[CmdletBinding()]

    [ValidateSet("VirtualMachines", "AppService", "SqlServers", "StorageAccounts", "KeyVaults", "ContainerRegistry", "KubernetesService")]
    [string]$Plan,
    [switch]$All
)
$plans = if ($All) {
    @("VirtualMachines", "AppService", "SqlServers", "StorageAccounts", "KeyVaults", "ContainerRegistry", "KubernetesService")
} elseif ($Plan) {
    @($Plan)
} else {
    throw "Specify -Plan or -All"
}
foreach ($p in $plans) {
    Write-Host "Enabling Defender for $p" -ForegroundColor Green
    Set-AzSecurityPricing -Name $p -PricingTier Standard
}\n

