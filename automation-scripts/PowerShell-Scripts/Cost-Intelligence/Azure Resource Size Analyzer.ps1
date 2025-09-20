<#
.SYNOPSIS
    Azure Resource Size Analyzer

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
        $sizeAnalysis = $sizeAnalysis + $analysis
    }
    Write-Host "VM Size Analysis:" -ForegroundColor Cyan
    $sizeAnalysis | Format-Table VMName, CurrentSize, Cores, MemoryMB, PowerState, Recommendation
$totalVMs = $sizeAnalysis.Count
$runningVMs = ($sizeAnalysis | Where-Object { $_.PowerState -eq "VM running" }).Count
    Write-Host "Summary:" -ForegroundColor Green
    Write-Host "Total VMs: $totalVMs" -ForegroundColor White
    Write-Host "Running VMs: $runningVMs" -ForegroundColor White
    Write-Host "Stopped VMs: $($totalVMs - $runningVMs)" -ForegroundColor Yellow
} catch { throw }\n