<#
.SYNOPSIS
    Test network connectivity

.DESCRIPTION
    Test network connectivity
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Network Connectivity Tester
# Test network connectivity between Azure resources
param(
    [Parameter(Mandatory)]
    [string]$SourceVMName,
    [Parameter(Mandatory)]
    [string]$TargetAddress,
    [Parameter()]
    [int]$Port = 80,
    [Parameter()]
    [string]$ResourceGroupName
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { 
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
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
    
    $result = Test-AzNetworkWatcherConnectivity -NetworkWatcher $networkWatcher @connectivityTest
    Write-Host "Connectivity Test Results:"
    Write-Host "Status: $($result.ConnectionStatus)" -ForegroundColor $(if($result.ConnectionStatus -eq "Reachable"){"Green"}else{"Red"})
    Write-Host "Average Latency: $($result.AvgLatencyInMs) ms"
    Write-Host "Min Latency: $($result.MinLatencyInMs) ms"
    Write-Host "Max Latency: $($result.MaxLatencyInMs) ms"
    Write-Host "Probes Sent: $($result.ProbesSent)"
    Write-Host "Probes Failed: $($result.ProbesFailed)"
} catch { throw }

