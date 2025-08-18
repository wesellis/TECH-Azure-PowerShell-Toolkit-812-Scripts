<#
.SYNOPSIS
    We Enhanced Azure Resource Size Analyzer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [int]$WEAnalysisDays = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEIncludeRecommendations
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName " Azure Resource Size Analyzer" -Version " 1.0" -Description " Analyze resource utilization and sizing"

try {
    if (-not (Test-AzureConnection)) { throw " Azure connection validation failed" }

    $vms = if ($WEResourceGroupName) {
        Get-AzVM -ResourceGroupName $WEResourceGroupName
    } else {
        Get-AzVM
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
            Recommendation = " Monitor" # Placeholder - would need actual metrics
        }
        
        $sizeAnalysis = $sizeAnalysis + $analysis
    }

    Write-WELog " VM Size Analysis:" " INFO" -ForegroundColor Cyan
    $sizeAnalysis | Format-Table VMName, CurrentSize, Cores, MemoryMB, PowerState, Recommendation

    $totalVMs = $sizeAnalysis.Count
   ;  $runningVMs = ($sizeAnalysis | Where-Object { $_.PowerState -eq " VM running" }).Count
    
    Write-WELog " Summary:" " INFO" -ForegroundColor Green
    Write-WELog "  Total VMs: $totalVMs" " INFO" -ForegroundColor White
    Write-WELog "  Running VMs: $runningVMs" " INFO" -ForegroundColor White
    Write-WELog "  Stopped VMs: $($totalVMs - $runningVMs)" " INFO" -ForegroundColor Yellow

} catch {
    Write-Log " ❌ Resource size analysis failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================