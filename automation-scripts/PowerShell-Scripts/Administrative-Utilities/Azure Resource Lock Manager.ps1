<#
.SYNOPSIS
    Azure Resource Lock Manager

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

<#
.SYNOPSIS
    We Enhanced Azure Resource Lock Manager

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(" Create" , " List" , " Remove" , " Audit" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELockName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" ReadOnly" , " Delete" )]
    [string]$WELockLevel = " Delete" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WELockNotes = " Created by Azure Automation" ,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEForce
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force

Show-Banner -ScriptName " Azure Resource Lock Manager" -Version " 1.0" -Description " Manage resource locks for protection and governance"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 3 -StepName " Connection" -Status " Validating Azure connection"
    if (-not (Test-AzureConnection)) {
        throw " Azure connection validation failed"
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 3 -StepName " Lock Operation" -Status " Executing $WEAction"
    
    switch ($WEAction) {
        " Create" {
            if (-not $WELockName) { $WELockName = " AutoLock-$(Get-Date -Format 'yyyyMMdd')" }
            
            if ($WEResourceName) {
                $resource = Get-AzResource -ResourceGroupName $WEResourceGroupName -Name $WEResourceName
                New-AzResourceLock -LockName $WELockName -LockLevel $WELockLevel -ResourceId $resource.ResourceId -LockNotes $WELockNotes
                Write-Log " ✓ Created $WELockLevel lock on resource: $WEResourceName" -Level SUCCESS
            } elseif ($WEResourceGroupName) {
                New-AzResourceLock -LockName $WELockName -LockLevel $WELockLevel -ResourceGroupName $WEResourceGroupName -LockNotes $WELockNotes
                Write-Log " ✓ Created $WELockLevel lock on resource group: $WEResourceGroupName" -Level SUCCESS
            } else {
                New-AzResourceLock -LockName $WELockName -LockLevel $WELockLevel -LockNotes $WELockNotes
                Write-Log " ✓ Created $WELockLevel lock on subscription" -Level SUCCESS
            }
        }
        
        " List" {
            if ($WEResourceGroupName) {
                $locks = Get-AzResourceLock -ResourceGroupName $WEResourceGroupName
            } else {
                $locks = Get-AzResourceLock
            }
            
            Write-WELog " Found $($locks.Count) resource locks:" " INFO" -ForegroundColor Cyan
            $locks | Format-Table Name, LockLevel, ResourceGroupName, ResourceName
        }
        
        " Remove" {
            if ($WELockName) {
                if ($WEResourceGroupName) {
                    Remove-AzResourceLock -LockName $WELockName -ResourceGroupName $WEResourceGroupName -Force:$WEForce
                } else {
                    Remove-AzResourceLock -LockName $WELockName -Force:$WEForce
                }
                Write-Log " ✓ Removed lock: $WELockName" -Level SUCCESS
            }
        }
        
        " Audit" {
           ;  $allLocks = Get-AzResourceLock
           ;  $lockReport = $allLocks | Group-Object LockLevel | ForEach-Object {
                @{
                    LockLevel = $_.Name
                    Count = $_.Count
                    Resources = $_.Group | Select-Object Name, ResourceGroupName, ResourceName
                }
            }
            
            Write-WELog " Lock Audit Summary:" " INFO" -ForegroundColor Cyan
            Write-WELog " Total Locks: $($allLocks.Count)" " INFO" -ForegroundColor White
            $lockReport | ForEach-Object {
                Write-WELog " $($_.LockLevel) Locks: $($_.Count)" " INFO" -ForegroundColor Yellow
            }
        }
    }

    Write-ProgressStep -StepNumber 3 -TotalSteps 3 -StepName " Complete" -Status " Operation complete"
    Write-Log " ✅ Resource lock operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log " ❌ Resource lock operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity " Resource Lock Management" -Completed


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================