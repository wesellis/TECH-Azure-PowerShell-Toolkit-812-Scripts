#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Manage resource locks

.DESCRIPTION
    Create, list, remove, or audit Azure resource locks
    Author: Wes Ellis (wes@wesellis.com)#>
#
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory)]
    [ValidateSet("Create", "List", "Remove", "Audit")]
    [string]$Action,
    [Parameter()]
    [string]$ResourceGroupName,
    [Parameter()]
    [string]$ResourceName,
    [Parameter()]
    [string]$LockName,
    [Parameter()]
    [ValidateSet("ReadOnly", "Delete")]
    [string]$LockLevel = "Delete",
    [Parameter()]
    [string]$LockNotes = "Lock created via script",
    [Parameter()]
    [switch]$Force
)
try {
        if (-not (Get-AzContext)) { Connect-AzAccount }
        switch ($Action) {
        "Create" {
            if (-not $LockName) { $LockName = "AutoLock-$(Get-Date -Format 'yyyyMMdd')" }
            if ($ResourceName) {
                $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $ResourceName
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -ResourceId $resource.ResourceId -LockNotes $LockNotes
                Write-Host "Lock created on resource: $ResourceName" -ForegroundColor Green
            } elseif ($ResourceGroupName) {
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -ResourceGroupName $ResourceGroupName -LockNotes $LockNotes
                Write-Host "Lock created on resource group: $ResourceGroupName" -ForegroundColor Green
            } else {
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -LockNotes $LockNotes
                Write-Host "Subscription-level lock created" -ForegroundColor Green
            }
        }
        "List" {
            if ($ResourceGroupName) {
                $locks = Get-AzResourceLock -ResourceGroupName $ResourceGroupName
            } else {
                $locks = Get-AzResourceLock
            }
            Write-Host "Found $($locks.Count) resource locks:"
            $locks | Format-Table Name, LockLevel, ResourceGroupName, ResourceName
        }
        "Remove" {
            if ($LockName) {
                if ($ResourceGroupName) {
                    if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
                } else {
                    if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
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
            Write-Host "Lock Audit Summary:"
            Write-Host "Total Locks: $($allLocks.Count)"
            $lockReport | ForEach-Object {
                Write-Host "$($_.LockLevel) Locks: $($_.Count)"
            }
        }
    }
    } catch { throw }

