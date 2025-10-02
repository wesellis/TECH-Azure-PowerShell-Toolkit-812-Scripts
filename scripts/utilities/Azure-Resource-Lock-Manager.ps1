#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage resource locks

.DESCRIPTION
    Create, list, remove, or audit Azure resource locks
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding(SupportsShouldProcess)]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [ValidateSet("Create", "List", "Remove", "Audit")]
    $Action,
    [Parameter()]
    $ResourceGroupName,
    [Parameter()]
    $ResourceName,
    [Parameter()]
    $LockName,
    [Parameter()]
    [ValidateSet("ReadOnly", "Delete")]
    $LockLevel = "Delete",
    [Parameter()]
    $LockNotes = "Lock created via script",
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
                Write-Output "Lock created on resource: $ResourceName" # Color: $2
            } elseif ($ResourceGroupName) {
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -ResourceGroupName $ResourceGroupName -LockNotes $LockNotes
                Write-Output "Lock created on resource group: $ResourceGroupName" # Color: $2
            } else {
                New-AzResourceLock -LockName $LockName -LockLevel $LockLevel -LockNotes $LockNotes
                Write-Output "Subscription-level lock created" # Color: $2
            }
        }
        "List" {
            if ($ResourceGroupName) {
                $locks = Get-AzResourceLock -ResourceGroupName $ResourceGroupName
            } else {
                $locks = Get-AzResourceLock
            }
            Write-Output "Found $($locks.Count) resource locks:"
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
            $AllLocks = Get-AzResourceLock -ErrorAction Stop
            $LockReport = $AllLocks | Group-Object LockLevel | ForEach-Object {
                @{
                    LockLevel = $_.Name
                    Count = $_.Count
                    Resources = $_.Group | Select-Object Name, ResourceGroupName, ResourceName
                }
            }
            Write-Output "Lock Audit Summary:"
            Write-Output "Total Locks: $($AllLocks.Count)"
            $LockReport | ForEach-Object {
                Write-Output "$($_.LockLevel) Locks: $($_.Count)"
            }
        }
    }
    } catch { throw`n}
