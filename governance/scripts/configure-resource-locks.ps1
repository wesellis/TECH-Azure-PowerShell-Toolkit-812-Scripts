#Requires -Module Az.Resources
#Requires -Version 5.1
<#
.SYNOPSIS
    configure resource locks
.DESCRIPTION
    configure resource locks operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Manages resource locks to prevent accidental deletion or modification

    Creates, removes, and audits resource locks at various scopes.
    Supports CanNotDelete and ReadOnly lock levels.
.PARAMETER Action
    Action to perform: Apply, Remove, List
.PARAMETER LockLevel
    Type of lock: CanNotDelete, ReadOnly
.PARAMETER LockName
    Name for the lock (auto-generates if not specified)
.PARAMETER Scope
    Resource scope for the lock (resource, resource group, or subscription)
.PARAMETER ResourceGroupName
    Target resource group
.PARAMETER ResourceName
    Specific resource to lock
.PARAMETER ResourceType
    Type of the resource when locking specific resource
.PARAMETER Notes
    Notes/reason for the lock
.PARAMETER Force
    Skip confirmation prompts

    .\configure-resource-locks.ps1 -Action Apply -ResourceGroupName "RG-Production" -LockLevel CanNotDelete

    Applies delete lock to resource group

    .\configure-resource-locks.ps1 -Action List -ResourceGroupName "RG-Production"

    Lists all locks in resource group

    Author: Azure PowerShell Toolkit#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Apply', 'Remove', 'List')]
    [string]$Action,

    [Parameter()]
    [ValidateSet('CanNotDelete', 'ReadOnly')]
    [string]$LockLevel = 'CanNotDelete',

    [Parameter()]
    [string]$LockName,

    [Parameter()]
    [string]$Scope,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$ResourceName,

    [Parameter()]
    [string]$ResourceType,

    [Parameter()]
    [string]$Notes = "Protected by policy",

    [Parameter()]
    [switch]$Force
)

# Error handling
$ErrorActionPreference = 'Stop'

function Test-Connection {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    return Get-AzContext
}

function Get-LockScope {
    if ($Scope) {
        return $Scope
    }
    elseif ($ResourceName -and $ResourceType -and $ResourceGroupName) {
        # Specific resource
        $resource = Get-AzResource -Name $ResourceName -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType
        return $resource.ResourceId
    }
    elseif ($ResourceGroupName) {
        # Resource group level
        $rg = Get-AzResourceGroup -Name $ResourceGroupName
        return $rg.ResourceId
    }
    else {
        # Subscription level
        $context = Get-AzContext
        return "/subscriptions/$($context.Subscription.Id)"
    }
}

function Apply-ResourceLock {
    param($Scope, $Name, $Level, $Notes)

    if (-not $Name) {
        $Name = "$Level-$(Get-Date -Format 'yyyyMMdd')"
    }

    $lockParams = @{
        LockName = $Name
        LockLevel = $Level
        Notes = $Notes
        Force = $true
    }

    # Determine scope type and apply appropriate parameters
    if ($Scope -match '/resourceGroups/[^/]+/providers/') {
        # Resource level lock
        $lockParams['ResourceName'] = $ResourceName
        $lockParams['ResourceType'] = $ResourceType
        $lockParams['ResourceGroupName'] = $ResourceGroupName
    }
    elseif ($Scope -match '/resourceGroups/[^/]+$') {
        # Resource group level lock
        $lockParams['ResourceGroupName'] = $Scope.Split('/')[-1]
    }
    # else subscription level, no additional params needed

    if ($PSCmdlet.ShouldProcess($Scope, "Apply $Level lock")) {
        try {
            $lock = New-AzResourceLock @lockParams
            Write-Host "Lock applied successfully: $($lock.Name)" -ForegroundColor Green
            return $lock
        }
        catch {
            if ($_.Exception.Message -match 'already exists') {
                Write-Warning "Lock already exists at this scope"
            }
            else {
                throw
            }
        }
    }
}

function Remove-ResourceLock {
    param($LockId)

    $lock = Get-AzResourceLock -LockId $LockId

    if ($PSCmdlet.ShouldProcess($lock.Name, "Remove lock")) {
        Remove-AzResourceLock -LockId $LockId -Force
        Write-Host "Lock removed: $($lock.Name)" -ForegroundColor Green
    }
}

function Get-ResourceLocks {
    param($Scope)

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

# Main execution
Write-Host "`nResource Lock Management" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-Connection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

switch ($Action) {
    'Apply' {
        $lockScope = Get-LockScope
        Write-Host "Applying $LockLevel lock to: $lockScope" -ForegroundColor Yellow

        $result = Apply-ResourceLock -Scope $lockScope -Name $LockName -Level $LockLevel -Notes $Notes

        if ($result) {
            Write-Host "`nLock Details:" -ForegroundColor Cyan
            Write-Host "Name: $($result.Name)"
            Write-Host "Level: $($result.Properties.level)"
            Write-Host "Notes: $($result.Properties.notes)"
        }
    }

    'Remove' {
        $locks = Get-ResourceLocks

        if ($locks.Count -eq 0) {
            Write-Warning "No locks found"
            return
        }

        if (-not $Force) {
            Write-Host "`nExisting Locks:" -ForegroundColor Yellow
            $locks | Format-Table -AutoSize

            $confirmation = Read-Host "`nEnter lock name to remove (or 'all' for all locks)"

            if ($confirmation -eq 'all') {
                foreach ($lock in $locks) {
                    Remove-ResourceLock -LockId $lock.Id
                }
            }
            else {
                $targetLock = $locks | Where-Object { $_.Name -eq $confirmation }
                if ($targetLock) {
                    Remove-ResourceLock -LockId $targetLock.Id
                }
                else {
                    Write-Warning "Lock not found: $confirmation"
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
            Write-Host "No locks found" -ForegroundColor Yellow
        }
        else {
            Write-Host "`nResource Locks:" -ForegroundColor Cyan
            $locks | Format-Table -AutoSize

            Write-Host "`nSummary:" -ForegroundColor Cyan
            Write-Host "Total Locks: $($locks.Count)"
            Write-Host "CanNotDelete: $(($locks | Where-Object Level -eq 'CanNotDelete').Count)"
            Write-Host "ReadOnly: $(($locks | Where-Object Level -eq 'ReadOnly').Count)"
        }
    }
}\n