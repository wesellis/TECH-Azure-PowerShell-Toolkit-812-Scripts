#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Resource Lock Manager

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
    $Action,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ResourceName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $LockName,
    [Parameter()]
    [ValidateSet("ReadOnly" , "Delete" )]
    $LockLevel = "Delete",
    [Parameter()]
    $LockNotes = "Lock created via script" ,
    [Parameter()]
    [switch]$Force
)
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
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
            Write-Output "Found $($locks.Count) resource locks:" # Color: $2
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
    $AllLocks = Get-AzResourceLock -ErrorAction Stop
    $LockReport = $AllLocks | Group-Object LockLevel | ForEach-Object {
                @{
                    LockLevel = $_.Name
                    Count = $_.Count
                    Resources = $_.Group | Select-Object Name, ResourceGroupName, ResourceName
                }
            }
            Write-Output "Lock Audit Summary:" # Color: $2
            Write-Output "Total Locks: $($AllLocks.Count)" # Color: $2
    $LockReport | ForEach-Object {
                Write-Output " $($_.LockLevel) Locks: $($_.Count)" # Color: $2
            }
        }
    }

} catch { throw`n}
