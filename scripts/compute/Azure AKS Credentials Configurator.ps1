#Requires -Version 7.4
#Requires -Modules Az.Aks

<#
.SYNOPSIS
    Azure AKS Credentials Configurator

.DESCRIPTION
    Azure automation for configuring kubectl credentials for AKS clusters

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ClusterName,

    [Parameter()]
    [switch]$Admin
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [AKS-Config] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Configuring kubectl credentials for AKS cluster: $ClusterName" "INFO"

    if ($Admin) {
        Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Admin -Force
        Write-Log "Admin credentials configured for cluster: $ClusterName" "SUCCESS"
    } else {
        Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Force
        Write-Log "User credentials configured for cluster: $ClusterName" "SUCCESS"
    }

    Write-Log "Testing connection..." "INFO"
    kubectl get nodes

    Write-Log "Kubectl is now configured for cluster: $ClusterName" "SUCCESS"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}