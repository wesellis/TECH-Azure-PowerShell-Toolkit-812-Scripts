#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Security

<#`n.SYNOPSIS
    Enable Defender

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
Enable Azure Defender plans
.PARAMETER Plan
Defender plan to enable (VirtualMachines, SqlServers, etc)
.PARAMETER All
Enable all standard plans
.\Enable-Defender.ps1 -All
.\Enable-Defender.ps1 -Plan VirtualMachines
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
    Write-Output "Enabling Defender for $p" # Color: $2
    Set-AzSecurityPricing -Name $p -PricingTier Standard`n}
