<#
.SYNOPSIS
    Azure Network Connectivity Tester

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
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
    Write-Host "Connectivity Test Results:" -ForegroundColor Cyan
    Write-Host "Status: $($result.ConnectionStatus)" -ForegroundColor $(if($result.ConnectionStatus -eq "Reachable" ){"Green" }else{"Red" })
    Write-Host "Average Latency: $($result.AvgLatencyInMs) ms" -ForegroundColor White
    Write-Host "Min Latency: $($result.MinLatencyInMs) ms" -ForegroundColor White
    Write-Host "Max Latency: $($result.MaxLatencyInMs) ms" -ForegroundColor White
    Write-Host "Probes Sent: $($result.ProbesSent)" -ForegroundColor White
    Write-Host "Probes Failed: $($result.ProbesFailed)" -ForegroundColor White
} catch { throw }

