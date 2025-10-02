#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Test network connectivity

.DESCRIPTION
    Test network connectivity
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    $SourceVMName,
    [Parameter(Mandatory)]
    $TargetAddress,
    [Parameter()]
    [int]$Port = 80,
    [Parameter()]
    $ResourceGroupName
)
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    $vm = Get-AzVM -Name $SourceVMName -ResourceGroupName $ResourceGroupName
    $NetworkWatcher = Get-AzNetworkWatcher -Location $vm.Location
    $ConnectivityTest = @{
        Source = @{
            ResourceId = $vm.Id
        }
        Destination = @{
            Address = $TargetAddress
            Port = $Port
        }
    }

    $result = Test-AzNetworkWatcherConnectivity -NetworkWatcher $NetworkWatcher @connectivityTest
    Write-Output "Connectivity Test Results:"
    Write-Output "Status: $($result.ConnectionStatus)" -ForegroundColor $(if($result.ConnectionStatus -eq "Reachable"){"Green"}else{"Red"})
    Write-Output "Average Latency: $($result.AvgLatencyInMs) ms"
    Write-Output "Min Latency: $($result.MinLatencyInMs) ms"
    Write-Output "Max Latency: $($result.MaxLatencyInMs) ms"
    Write-Output "Probes Sent: $($result.ProbesSent)"
    Write-Output "Probes Failed: $($result.ProbesFailed)"
} catch { throw`n}
