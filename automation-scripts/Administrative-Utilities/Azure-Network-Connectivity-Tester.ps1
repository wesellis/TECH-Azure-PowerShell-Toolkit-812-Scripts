# Azure Network Connectivity Tester
# Test network connectivity between Azure resources
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceVMName,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetAddress,
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 80,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Network Connectivity Tester" -Version "1.0" -Description "Test network connectivity"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.Network'))) {
        throw "Azure connection validation failed"
    }

    $vm = Get-AzVM -Name $SourceVMName -ResourceGroupName $ResourceGroupName
    $networkWatcher = Get-AzNetworkWatcher -Location $vm.Location

    $connectivityTest = @{
        Source = @{
            ResourceId = $vm.Id
        }
        Destination = @{
            Address = $TargetAddress
            Port = $Port
        }
    }

    Write-Log "🔍 Testing connectivity from $SourceVMName to $TargetAddress`:$Port..." -Level INFO
    
    $result = Test-AzNetworkWatcherConnectivity -NetworkWatcher $networkWatcher @connectivityTest
    
    Write-Host "Connectivity Test Results:" -ForegroundColor Cyan
    Write-Host "Status: $($result.ConnectionStatus)" -ForegroundColor $(if($result.ConnectionStatus -eq "Reachable"){"Green"}else{"Red"})
    Write-Host "Average Latency: $($result.AvgLatencyInMs) ms" -ForegroundColor White
    Write-Host "Min Latency: $($result.MinLatencyInMs) ms" -ForegroundColor White
    Write-Host "Max Latency: $($result.MaxLatencyInMs) ms" -ForegroundColor White
    Write-Host "Probes Sent: $($result.ProbesSent)" -ForegroundColor White
    Write-Host "Probes Failed: $($result.ProbesFailed)" -ForegroundColor White

} catch {
    Write-Log "❌ Network connectivity test failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
