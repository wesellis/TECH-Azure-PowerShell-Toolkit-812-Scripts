<#
.SYNOPSIS
    We Enhanced Azure Network Connectivity Tester

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESourceVMName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETargetAddress,
    
    [Parameter(Mandatory=$false)]
    [int]$WEPort = 80,
    
    [Parameter(Mandatory=$false)]
    [string]$WEResourceGroupName
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName " Azure Network Connectivity Tester" -Version " 1.0" -Description " Test network connectivity"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.Network'))) {
        throw " Azure connection validation failed"
    }

    $vm = Get-AzVM -Name $WESourceVMName -ResourceGroupName $WEResourceGroupName
    $networkWatcher = Get-AzNetworkWatcher -Location $vm.Location

    $connectivityTest = @{
        Source = @{
            ResourceId = $vm.Id
        }
        Destination = @{
            Address = $WETargetAddress
            Port = $WEPort
        }
    }

    Write-Log " 🔍 Testing connectivity from $WESourceVMName to $WETargetAddress`:$WEPort..." -Level INFO
    
   ;  $result = Test-AzNetworkWatcherConnectivity -NetworkWatcher $networkWatcher @connectivityTest
    
    Write-WELog " Connectivity Test Results:" " INFO" -ForegroundColor Cyan
    Write-WELog " Status: $($result.ConnectionStatus)" " INFO" -ForegroundColor $(if($result.ConnectionStatus -eq " Reachable"){" Green"}else{" Red"})
    Write-WELog " Average Latency: $($result.AvgLatencyInMs) ms" " INFO" -ForegroundColor White
    Write-WELog " Min Latency: $($result.MinLatencyInMs) ms" " INFO" -ForegroundColor White
    Write-WELog " Max Latency: $($result.MaxLatencyInMs) ms" " INFO" -ForegroundColor White
    Write-WELog " Probes Sent: $($result.ProbesSent)" " INFO" -ForegroundColor White
    Write-WELog " Probes Failed: $($result.ProbesFailed)" " INFO" -ForegroundColor White

} catch {
    Write-Log " ❌ Network connectivity test failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================