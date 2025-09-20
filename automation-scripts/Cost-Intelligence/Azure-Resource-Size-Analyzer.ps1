<#
.SYNOPSIS
    Analyze resource sizes

.DESCRIPTION
    Analyze resource sizes
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Resource Size Analyzer
# Analyze and recommend right-sizing for Azure resources
param(
    [Parameter()]
    [string]$ResourceGroupName,
    [Parameter()]
    [int]$AnalysisDays = 30,
    [Parameter()]
    [switch]$IncludeRecommendations
)
try {
    if (-not (Get-AzContext)) { throw "Not connected to Azure" }
    $vms = if ($ResourceGroupName) {
        Get-AzVM -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzVM -ErrorAction Stop
    }
    $sizeAnalysis = @()
    foreach ($vm in $vms) {
        $vmSize = Get-AzVMSize -Location $vm.Location | Where-Object { $_.Name -eq $vm.HardwareProfile.VmSize }
        # Get basic metrics (simplified for demo)
        $analysis = [PSCustomObject]@{
            VMName = $vm.Name
            ResourceGroup = $vm.ResourceGroupName
            CurrentSize = $vm.HardwareProfile.VmSize
            Cores = $vmSize.NumberOfCores
            MemoryMB = $vmSize.MemoryInMB
            MaxDataDisks = $vmSize.MaxDataDiskCount
            PowerState = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses[1].DisplayStatus
            Recommendation = "Monitor" # Placeholder - would need actual metrics
        }
        $sizeAnalysis += $analysis
    }
    Write-Host "VM Size Analysis:"
    $sizeAnalysis | Format-Table VMName, CurrentSize, Cores, MemoryMB, PowerState, Recommendation
    $totalVMs = $sizeAnalysis.Count
    $runningVMs = ($sizeAnalysis | Where-Object { $_.PowerState -eq "VM running" }).Count
    Write-Host "Summary:"
    Write-Host "Total VMs: $totalVMs"
    Write-Host "Running VMs: $runningVMs"
    Write-Host "Stopped VMs: $($totalVMs - $runningVMs)"
} catch { throw }

