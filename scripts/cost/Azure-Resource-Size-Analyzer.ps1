#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Analyze resource sizes

.DESCRIPTION
    Analyze resource sizes
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
    $SizeAnalysis = @()
    foreach ($vm in $vms) {
        $VmSize = Get-AzVMSize -Location $vm.Location | Where-Object { $_.Name -eq $vm.HardwareProfile.VmSize }
        $analysis = [PSCustomObject]@{
            VMName = $vm.Name
            ResourceGroup = $vm.ResourceGroupName
            CurrentSize = $vm.HardwareProfile.VmSize
            Cores = $VmSize.NumberOfCores
            MemoryMB = $VmSize.MemoryInMB
            MaxDataDisks = $VmSize.MaxDataDiskCount
            PowerState = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses[1].DisplayStatus
            Recommendation = "Monitor" # Placeholder - would need actual metrics
        }
        $SizeAnalysis += $analysis
    }
    Write-Output "VM Size Analysis:"
    $SizeAnalysis | Format-Table VMName, CurrentSize, Cores, MemoryMB, PowerState, Recommendation
    $TotalVMs = $SizeAnalysis.Count
    $RunningVMs = ($SizeAnalysis | Where-Object { $_.PowerState -eq "VM running" }).Count
    Write-Output "Summary:"
    Write-Output "Total VMs: $TotalVMs"
    Write-Output "Running VMs: $RunningVMs"
    Write-Output "Stopped VMs: $($TotalVMs - $RunningVMs)"
} catch { throw`n}
