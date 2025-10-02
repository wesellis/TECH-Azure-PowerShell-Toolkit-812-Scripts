#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Aks Status Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
;
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$ClusterName
)
Write-Output "Monitoring AKS Cluster: $ClusterName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output " ============================================"
    $AksCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $ClusterName
Write-Output "Cluster Information:"
Write-Output "Name: $($AksCluster.Name)"
Write-Output "Location: $($AksCluster.Location)"
Write-Output "Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Output "Provisioning State: $($AksCluster.ProvisioningState)"
Write-Output "Power State: $($AksCluster.PowerState.Code)"
Write-Output "DNS Prefix: $($AksCluster.DnsPrefix)"
Write-Output "FQDN: $($AksCluster.Fqdn)"
Write-Output " `nNode Pool Information:"
foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
    Write-Output "Pool Name: $($NodePool.Name)"
    Write-Output "VM Size: $($NodePool.VmSize)"
    Write-Output "Node Count: $($NodePool.Count)"
    Write-Output "OS Type: $($NodePool.OsType)"
    Write-Output "Provisioning State: $($NodePool.ProvisioningState)"
    Write-Output "  ---"
}
Write-Output " `nCluster monitoring completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
