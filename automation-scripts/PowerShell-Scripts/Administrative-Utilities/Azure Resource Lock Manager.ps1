<#
.SYNOPSIS
    Azure Resource Lock Manager

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Create" , "List" , "Remove" , "Audit" )]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Action,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LockName,
    [Parameter()]
    [ValidateSet("ReadOnly" , "Delete" )]
    [string]$LockLevel = "Delete",
    [Parameter()]
    [string]$LockNotes = "Lock created via script" ,
    [Parameter()]
    [switch]$Force
)
Write-Host "Script Started" -ForegroundColor Green
try {
    # Progress stepNumber 1 -TotalSteps 3 -StepName "Connection" -Status "Validating Azure connection"
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    # Progress stepNumber 2 -TotalSteps 3 -StepName "Lock Operation" -Status "Executing $Action"
    switch ($Action) {
        "Create" {
            if (-not $LockName) { $LockName = "AutoLock-$(Get-Date -Format 'yyyyMMdd')" }
            if ($ResourceName) {
                $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $ResourceName
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -ResourceId $resource.ResourceId -LockNotes $LockNotes

            } elseif ($ResourceGroupName) {
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -ResourceGroupName $ResourceGroupName -LockNotes $LockNotes

            } else {
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -LockNotes $LockNotes

            }
        }
        "List" {
            if ($ResourceGroupName) {
                $locks = Get-AzResourceLock -ResourceGroupName $ResourceGroupName
            } else {
                $locks = Get-AzResourceLock -ErrorAction Stop
            }
            Write-Host "Found $($locks.Count) resource locks:" -ForegroundColor Cyan
            $locks | Format-Table Name, LockLevel, ResourceGroupName, ResourceName
        }
        "Remove" {
            if ($LockName) {
                if ($ResourceGroupName) {
                    Remove-AzResourceLock -LockName $LockName -ResourceGroupName $ResourceGroupName -Force:$Force
                } else {
                    Remove-AzResourceLock -LockName $LockName -Force:$Force
                }

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
            Write-Host "Lock Audit Summary:" -ForegroundColor Cyan
            Write-Host "Total Locks: $($allLocks.Count)" -ForegroundColor White
            $lockReport | ForEach-Object {
                Write-Host " $($_.LockLevel) Locks: $($_.Count)" -ForegroundColor Yellow
            }
        }
    }
    # Progress stepNumber 3 -TotalSteps 3 -StepName "Complete" -Status "Operation complete"

} catch { throw }\n