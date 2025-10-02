#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    configure resource locks
.DESCRIPTION
    configure resource locks operation
    Author: Wes Ellis (wes@wesellis.com)

    Manages resource locks to prevent accidental deletion or modification

    Creates, removes, and audits resource locks at various scopes.
    Supports CanNotDelete and ReadOnly lock levels.
.parameter Action
    Action to perform: Apply, Remove, List
.parameter LockLevel
    Type of lock: CanNotDelete, ReadOnly
.parameter LockName
    Name for the lock (auto-generates if not specified)
.parameter Scope
    Resource scope for the lock (resource, resource group, or subscription)
.parameter ResourceGroupName
    Target resource group
.parameter ResourceName
    Specific resource to lock
.parameter ResourceType
    Type of the resource when locking specific resource
.parameter Notes
    Notes/reason for the lock
.parameter Force
    Skip confirmation prompts

    .\configure-resource-locks.ps1 -Action Apply -ResourceGroupName "RG-Production" -LockLevel CanNotDelete

    Applies delete lock to resource group

    .\configure-resource-locks.ps1 -Action List -ResourceGroupName "RG-Production"

    Lists all locks in resource group

    Author: Azure PowerShell Toolkit

[parameter(Mandatory = $true)]
    [ValidateSet('Apply', 'Remove', 'List')]
    [string]$Action,

    [parameter()]
    [ValidateSet('CanNotDelete', 'ReadOnly')]
    [string]$LockLevel = 'CanNotDelete',

    [parameter()]
    [string]$LockName,

    [parameter()]
    [string]$Scope,

    [parameter()]
    [string]$ResourceGroupName,

    [parameter()]
    [string]$ResourceName,

    [parameter()]
    [string]$ResourceType,

    [parameter()]
    [string]$Notes = "Protected by policy",

    [parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

[OutputType([string])] 
 {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    return Get-AzContext
}

function Get-LockScope {
    if ($Scope) {
        return $Scope
    }
    elseif ($ResourceName -and $ResourceType -and $ResourceGroupName) {
        $resource = Get-AzResource -Name $ResourceName -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType
        return $resource.ResourceId
    }
    elseif ($ResourceGroupName) {
        $rg = Get-AzResourceGroup -Name $ResourceGroupName
        return $rg.ResourceId
    }
    else {
        $context = Get-AzContext
        return "/subscriptions/$($context.Subscription.Id)"
    }
}

function Apply-ResourceLock {
    $Scope, $Name, $Level, $Notes)

    if (-not $Name) {
        $Name = "$Level-$(Get-Date -Format 'yyyyMMdd')"
    }

    $LockParams = @{
        LockName = $Name
        LockLevel = $Level
        Notes = $Notes
        Force = $true
    }

    if ($Scope -match '/resourceGroups/[^/]+/providers/') {
        $LockParams['ResourceName'] = $ResourceName
        $LockParams['ResourceType'] = $ResourceType
        $LockParams['ResourceGroupName'] = $ResourceGroupName
    }
    elseif ($Scope -match '/resourceGroups/[^/]+$') {
        $LockParams['ResourceGroupName'] = $Scope.Split('/')[-1]
    }

    if ($PSCmdlet.ShouldProcess($Scope, "Apply $Level lock")) {
        try {
            $lock = New-AzResourceLock @lockParams
            Write-Host "Lock applied successfully: $($lock.Name)" -ForegroundColor Green
            return $lock
        }
        catch {
            if ($_.Exception.Message -match 'already exists') {
                write-Warning "Lock already exists at this scope"
            }
            else {
                throw
            }
        }
    }
}

function Remove-ResourceLock {
    $LockId)

    $lock = Get-AzResourceLock -LockId $LockId

    if ($PSCmdlet.ShouldProcess($lock.Name, "Remove lock")) {
        Remove-AzResourceLock -LockId $LockId -Force
        Write-Host "Lock removed: $($lock.Name)" -ForegroundColor Green
    }
}

function Get-ResourceLocks {
    $Scope)

    $locks = if ($ResourceGroupName) {
        Get-AzResourceLock -ResourceGroupName $ResourceGroupName
    }
    else {
        Get-AzResourceLock
    }

    $locks | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Level = $_.Properties.level
            Scope = if ($_.ResourceId -match '/resourceGroups/([^/]+)') { $Matches[1] } else { 'Subscription' }
            Notes = $_.Properties.notes
            CreatedOn = $_.Properties.createdOn
            Id = $_.LockId
        }
    }
}

Write-Host "`nResource Lock Management" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-Connection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

switch ($Action) {
    'Apply' {
        $LockScope = Get-LockScope
        Write-Host "Applying $LockLevel lock to: $LockScope" -ForegroundColor Green

        $result = Apply-ResourceLock -Scope $LockScope -Name $LockName -Level $LockLevel -Notes $Notes

        if ($result) {
            Write-Host "`nLock Details:" -ForegroundColor Green
            Write-Output "Name: $($result.Name)"
            Write-Output "Level: $($result.Properties.level)"
            Write-Output "Notes: $($result.Properties.notes)"
        }
    }

    'Remove' {
        $locks = Get-ResourceLocks

        if ($locks.Count -eq 0) {
            write-Warning "No locks found"
            return
        }

        if (-not $Force) {
            Write-Host "`nExisting Locks:" -ForegroundColor Green
            $locks | Format-Table -AutoSize

            $confirmation = Read-Host "`nEnter lock name to remove (or 'all' for all locks)"

            if ($confirmation -eq 'all') {
                foreach ($lock in $locks) {
                    Remove-ResourceLock -LockId $lock.Id
                }
            }
            else {
                $TargetLock = $locks | Where-Object { $_.Name -eq $confirmation }
                if ($TargetLock) {
                    Remove-ResourceLock -LockId $TargetLock.Id
                }
                else {
                    write-Warning "Lock not found: $confirmation"
                }
            }
        }
        else {
            foreach ($lock in $locks) {
                Remove-ResourceLock -LockId $lock.Id
            }
        }
    }

    'List' {
        $locks = Get-ResourceLocks

        if ($locks.Count -eq 0) {
            Write-Host "No locks found" -ForegroundColor Green
        }
        else {
            Write-Host "`nResource Locks:" -ForegroundColor Green
            $locks | Format-Table -AutoSize

            Write-Host "`nSummary:" -ForegroundColor Green
            Write-Output "Total Locks: $($locks.Count)"
            Write-Output "CanNotDelete: $(($locks | Where-Object Level -eq 'CanNotDelete').Count)"
            Write-Output "ReadOnly: $(($locks | Where-Object Level -eq 'ReadOnly').Count)"
        }
    }
}\n



