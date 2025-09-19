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
# Azure Resource Lock Manager
# Professional utility for managing resource locks across Azure resources
# Version: 1.0 | Resource protection and governance

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Create", "List", "Remove", "Audit")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceName,
    
    [Parameter(Mandatory=$false)]
    [string]$LockName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("ReadOnly", "Delete")]
    [string]$LockLevel = "Delete",
    
    [Parameter(Mandatory=$false)]
    [string]$LockNotes = "Created by Azure Automation",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

#region Functions

# Import common functions
# Module import removed - use #Requires instead

Show-Banner -ScriptName "Azure Resource Lock Manager" -Version "1.0" -Description "Manage resource locks for protection and governance"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 3 -StepName "Connection" -Status "Validating Azure connection"
    if (-not (Test-AzureConnection)) {
        throw "Azure connection validation failed"
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 3 -StepName "Lock Operation" -Status "Executing $Action"
    
    switch ($Action) {
        "Create" {
            if (-not $LockName) { $LockName = "AutoLock-$(Get-Date -Format 'yyyyMMdd')" }
            
            if ($ResourceName) {
                $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $ResourceName
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -ResourceId $resource.ResourceId -LockNotes $LockNotes
                Write-Log "[OK] Created $LockLevel lock on resource: $ResourceName" -Level SUCCESS
            } elseif ($ResourceGroupName) {
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -ResourceGroupName $ResourceGroupName -LockNotes $LockNotes
                Write-Log "[OK] Created $LockLevel lock on resource group: $ResourceGroupName" -Level SUCCESS
            } else {
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -LockNotes $LockNotes
                Write-Log "[OK] Created $LockLevel lock on subscription" -Level SUCCESS
            }
        }
        
        "List" {
            if ($ResourceGroupName) {
                $locks = Get-AzResourceLock -ResourceGroupName $ResourceGroupName
            } else {
                $locks = Get-AzResourceLock -ErrorAction Stop
            }
            
            Write-Information "Found $($locks.Count) resource locks:"
            $locks | Format-Table Name, LockLevel, ResourceGroupName, ResourceName
        }
        
        "Remove" {
            if ($LockName) {
                if ($ResourceGroupName) {
                    Remove-AzResourceLock -LockName $LockName -ResourceGroupName $ResourceGroupName -Force:$Force
                } else {
                    Remove-AzResourceLock -LockName $LockName -Force:$Force
                }
                Write-Log "[OK] Removed lock: $LockName" -Level SUCCESS
            }
        }
        
        "Audit" {
            $allLocks = Get-AzResourceLock -ErrorAction Stop
            $lockReport = $allLocks | Group-Object LockLevel | ForEach-Object {
                @{
                    LockLevel = $_.Name
                    Count = $_.Count
                    Resources = $_.Group | Select-Object Name, ResourceGroupName, ResourceName
                }
            }
            
            Write-Information "Lock Audit Summary:"
            Write-Information "Total Locks: $($allLocks.Count)"
            $lockReport | ForEach-Object {
                Write-Information "$($_.LockLevel) Locks: $($_.Count)"
            }
        }
    }

    Write-ProgressStep -StepNumber 3 -TotalSteps 3 -StepName "Complete" -Status "Operation complete"
    Write-Log " Resource lock operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log " Resource lock operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity "Resource Lock Management" -Completed

#endregion
