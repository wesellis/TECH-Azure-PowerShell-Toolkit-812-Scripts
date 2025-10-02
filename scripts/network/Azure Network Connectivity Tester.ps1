#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Network Connectivity Tester

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceVMName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetAddress,
    [Parameter()]
    [int]$Port = 80,
    [Parameter()]
    [string]$ResourceGroupName
)
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    [string]$vm = Get-AzVM -Name $SourceVMName -ResourceGroupName $ResourceGroupName
    [string]$NetworkWatcher = Get-AzNetworkWatcher -Location $vm.Location
    $ConnectivityTest = @{
        Source = @{
            ResourceId = $vm.Id
        }
        Destination = @{
            Address = $TargetAddress
            Port = $Port
        }
    }
    [string]$result = Test-AzNetworkWatcherConnectivity -NetworkWatcher $NetworkWatcher @connectivityTest
    Write-Output "Connectivity Test Results:" # Color: $2
    Write-Output "Status: $($result.ConnectionStatus)" -ForegroundColor $(if($result.ConnectionStatus -eq "Reachable" ){"Green" }else{"Red" })
    Write-Output "Average Latency: $($result.AvgLatencyInMs) ms" # Color: $2
    Write-Output "Min Latency: $($result.MinLatencyInMs) ms" # Color: $2
    Write-Output "Max Latency: $($result.MaxLatencyInMs) ms" # Color: $2
    Write-Output "Probes Sent: $($result.ProbesSent)" # Color: $2
    Write-Output "Probes Failed: $($result.ProbesFailed)" # Color: $2
} catch { throw`n}
