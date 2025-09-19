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
# Azure Resource Size Analyzer
# Analyze and recommend right-sizing for Azure resources
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [int]$AnalysisDays = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeRecommendations
)

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName "Azure Resource Size Analyzer" -Version "1.0" -Description "Analyze resource utilization and sizing"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection validation failed" }

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

    Write-Information "VM Size Analysis:"
    $sizeAnalysis | Format-Table VMName, CurrentSize, Cores, MemoryMB, PowerState, Recommendation

    $totalVMs = $sizeAnalysis.Count
    $runningVMs = ($sizeAnalysis | Where-Object { $_.PowerState -eq "VM running" }).Count
    
    Write-Information "Summary:"
    Write-Information "  Total VMs: $totalVMs"
    Write-Information "  Running VMs: $runningVMs"
    Write-Information "  Stopped VMs: $($totalVMs - $runningVMs)"

} catch {
    Write-Log " Resource size analysis failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}


#endregion
