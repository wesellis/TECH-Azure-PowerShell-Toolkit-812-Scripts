#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Azure Network Connectivity Tester
# Test network connectivity between Azure resources
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

#region Functions

# Module import removed - use #Requires instead
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

    Write-Log " Testing connectivity from $SourceVMName to $TargetAddress`:$Port..." -Level INFO
    
    $result = Test-AzNetworkWatcherConnectivity -NetworkWatcher $networkWatcher @connectivityTest
    
    Write-Information "Connectivity Test Results:"
    Write-Information "Status: $($result.ConnectionStatus)" -ForegroundColor $(if($result.ConnectionStatus -eq "Reachable"){"Green"}else{"Red"})
    Write-Information "Average Latency: $($result.AvgLatencyInMs) ms"
    Write-Information "Min Latency: $($result.MinLatencyInMs) ms"
    Write-Information "Max Latency: $($result.MaxLatencyInMs) ms"
    Write-Information "Probes Sent: $($result.ProbesSent)"
    Write-Information "Probes Failed: $($result.ProbesFailed)"

} catch {
    Write-Log " Network connectivity test failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}


#endregion
