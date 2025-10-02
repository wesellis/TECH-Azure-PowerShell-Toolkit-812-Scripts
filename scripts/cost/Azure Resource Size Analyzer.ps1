#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#.SYNOPSIS
    Azure Resource Size Analyzer

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [int]$AnalysisDays = 30,
    [Parameter()]
    [switch]$IncludeRecommendations
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    [string]$vms = if ($ResourceGroupName) {
        Get-AzVM -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzVM -ErrorAction Stop
    }
    [string]$SizeAnalysis = @()
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
    [string]$SizeAnalysis = $SizeAnalysis + $analysis
    }
    Write-Host "VM Size Analysis:" -ForegroundColor Green
    [string]$SizeAnalysis | Format-Table VMName, CurrentSize, Cores, MemoryMB, PowerState, Recommendation
    [string]$TotalVMs = $SizeAnalysis.Count
    [string]$RunningVMs = ($SizeAnalysis | Where-Object { $_.PowerState -eq "VM running" }).Count
    Write-Host "Summary:" -ForegroundColor Green
    Write-Host "Total VMs: $TotalVMs" -ForegroundColor Green
    Write-Host "Running VMs: $RunningVMs" -ForegroundColor Green
    Write-Host "Stopped VMs: $($TotalVMs - $RunningVMs)" -ForegroundColor Green
} catch { throw`n}
