#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    remediate compliance
.DESCRIPTION
    remediate compliance operation
    Author: Wes Ellis (wes@wesellis.com)

    Remediates non-compliant Azure resources based on policy assignments

    Identifies and remediates non-compliant resources by triggering
    remediation tasks for policies that support automatic remediation.
    Supports bulk remediation and monitoring of remediation progress.
.parameter SubscriptionId
    Target subscription for remediation
.parameter PolicyAssignmentName
    Specific policy assignment to remediate
.parameter ResourceGroupName
    Limit remediation to specific resource group
.parameter MaxResources
    Maximum number of resources to remediate at once
.parameter RemediationMode
    Remediation mode: Auto, Manual, Preview
.parameter WaitForCompletion
    Wait for remediation tasks to complete
.parameter TimeoutMinutes
    Timeout for waiting on remediation completion
.parameter ExcludeResourceTypes
    Resource types to exclude from remediation
.parameter DryRun
    Preview remediation actions without executing

    .\remediate-compliance.ps1 -PolicyAssignmentName "audit-vm-backup" -RemediationMode Auto

    Automatically remediate non-compliant VMs for backup policy

    .\remediate-compliance.ps1 -ResourceGroupName "RG-Prod" -DryRun

    Preview remediation actions for production resource group

[parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [parameter()]
    [string]$PolicyAssignmentName,

    [parameter()]
    [string]$ResourceGroupName,

    [parameter()]
    [ValidateRange(1, 500)]
    [int]$MaxResources = 100,

    [parameter()]
    [ValidateSet('Auto', 'Manual', 'Preview')]
    [string]$RemediationMode = 'Manual',

    [parameter()]
    [switch]$WaitForCompletion,

    [parameter()]
    [ValidateRange(1, 480)]
    [int]$TimeoutMinutes = 60,

    [parameter()]
    [string[]]$ExcludeResourceTypes,

    [parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    return Get-AzContext
}

function Get-RemediableViolations {
    [string]$PolicyAssignment,
        [string]$ResourceGroup,
        [int]$MaxResults,
        [string[]]$ExcludeTypes
    )

    Write-Host "Finding non-compliant resources..." -ForegroundColor Green

    try {
        $params = @{
            ComplianceState = 'NonCompliant'
            Top = $MaxResults
        }

        if ($PolicyAssignment) {
            $params['PolicyAssignmentName'] = $PolicyAssignment
        }

        if ($ResourceGroup) {
            $params['ResourceGroupName'] = $ResourceGroup
        }

        $violations = Get-AzPolicyState @params

        if ($ExcludeTypes) {
            $violations = $violations | Where-Object { $_.ResourceType -notin $ExcludeTypes }
        }

        $RemediableViolations = $violations | Where-Object {
            $PolicyDef = Get-AzPolicyDefinition -Id $_.PolicyDefinitionId -ErrorAction SilentlyContinue
            if ($PolicyDef) {
                $effect = $PolicyDef.Properties.PolicyRule.then.effect
                return $effect -in @('deployIfNotExists', 'modify')
            }
            return $false
        }

        Write-Host "Found $($violations.Count) non-compliant resources, $($RemediableViolations.Count) are remediable" -ForegroundColor Green

        return $RemediableViolations
    }
    catch {
        write-Error "Failed to retrieve policy violations: $_"
        throw
    }
}

function Get-PolicyAssignments {
    [string]$ResourceGroup
    )

    try {
        $params = @{}
        if ($ResourceGroup) {
            $params['Scope'] = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroup"
        }

        $assignments = Get-AzPolicyAssignment @params
        return $assignments | Where-Object {
            $PolicyDef = Get-AzPolicyDefinition -Id $_.Properties.PolicyDefinitionId -ErrorAction SilentlyContinue
            if ($PolicyDef) {
                $effect = $PolicyDef.Properties.PolicyRule.then.effect
                return $effect -in @('deployIfNotExists', 'modify')
            }
            return $false

} catch {
        write-Error "Failed to retrieve policy assignments: $_"
        throw
    }
}

function New-RemediationTask {
    [object]$PolicyAssignment,
        [array]$Violations,
        [string]$Mode
    )

    $AssignmentName = $PolicyAssignment.Name
    $RemediationName = "remediation-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    Write-Host "Creating remediation task for: $AssignmentName" -ForegroundColor Green

    try {
        if ($PSCmdlet.ShouldProcess($AssignmentName, "Create remediation task")) {
            $params = @{
                Name = $RemediationName
                PolicyAssignmentId = $PolicyAssignment.ResourceId
                Scope = $PolicyAssignment.Properties.Scope
            }

            if ($Violations.Count -le 50) {
                $ResourceIds = $Violations | Select-Object -ExpandProperty ResourceId
                $params['ResourceIdentifier'] = $ResourceIds
            }

            $remediation = Start-AzPolicyRemediation @params

            Write-Host "Remediation task created: $RemediationName" -ForegroundColor Green
            Write-Host "Task ID: $($remediation.Id)" -ForegroundColor Green
            Write-Host "Resources to remediate: $($Violations.Count)" -ForegroundColor Green

            return $remediation

} catch {
        write-Error "Failed to create remediation task for $AssignmentName : $_"
        return $null
    }
}

function Wait-ForRemediationCompletion {
    [array]$RemediationTasks,
        [int]$TimeoutMinutes
    )

    if ($RemediationTasks.Count -eq 0) {
        return
    }

    Write-Host "Monitoring remediation progress..." -ForegroundColor Green
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)

    do {
        $AllCompleted = $true
        $InProgress = 0
        $completed = 0
        $failed = 0

        foreach ($task in $RemediationTasks) {
            try {
                $status = Get-AzPolicyRemediation -Name $task.Name -Scope $task.Properties.Scope

                switch ($status.Properties.ProvisioningState) {
                    'Succeeded' { $completed++ }
                    'Failed' { $failed++; $AllCompleted = $false }
                    'Canceled' { $failed++; $AllCompleted = $false }
                    default { $InProgress++; $AllCompleted = $false }

} catch {
                write-Warning "Could not get status for remediation task: $($task.Name)"
                $AllCompleted = $false
            }
        }

        Write-Host "Remediation Status - Completed: $completed, In Progress: $InProgress, Failed: $failed" -ForegroundColor Green

        if (-not $AllCompleted -and (Get-Date) -lt $timeout) {
            Start-Sleep -Seconds 30
        }
    } while (-not $AllCompleted -and (Get-Date) -lt $timeout)

    if ($AllCompleted) {
        Write-Host "All remediation tasks completed!" -ForegroundColor Green
    } else {
        write-Warning "Remediation tasks did not complete within the timeout period"
    }
}

function Show-RemediationSummary {
    [array]$Violations,
        [array]$RemediationTasks,
        [bool]$IsDryRun
    )

    Write-Host "`nRemediation Summary" -ForegroundColor Green
    write-Host ("=" * 50) -ForegroundColor Cyan

    if ($IsDryRun) {
        Write-Host "DRY RUN - No actual remediation performed" -ForegroundColor Green
    }

    Write-Output "Non-compliant resources found: $($Violations.Count)"
    Write-Output "Remediation tasks created: $($RemediationTasks.Count)"

    if ($Violations.Count -gt 0) {
        Write-Host "`nViolations by Resource Type:" -ForegroundColor Green
        $Violations | Group-Object ResourceType | Sort-Object Count -Descending | ForEach-Object {
            Write-Output "  $($_.Name): $($_.Count)"
        }

        Write-Host "`nViolations by Policy:" -ForegroundColor Green
        $Violations | Group-Object PolicyDefinitionId | Sort-Object Count -Descending | ForEach-Object {
            $PolicyName = ($_.Name -split '/')[-1]
            Write-Output "  $PolicyName : $($_.Count)"
        }
    }

    if ($RemediationTasks.Count -gt 0) {
        Write-Host "`nRemediation Tasks:" -ForegroundColor Green
        $RemediationTasks | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Green
        }
    }
}

function Get-RemediationGuidance {
    [array]$Violations)

    $guidance = @()

    $PolicyGroups = $Violations | Group-Object PolicyDefinitionId

    foreach ($group in $PolicyGroups) {
        $PolicyId = $group.Name
        $count = $group.Count

        try {
            $PolicyDef = Get-AzPolicyDefinition -Id $PolicyId -ErrorAction SilentlyContinue
            if ($PolicyDef) {
                $PolicyName = $PolicyDef.Properties.DisplayName
                $effect = $PolicyDef.Properties.PolicyRule.then.effect

                switch ($effect) {
                    'deployIfNotExists' {
                        $guidance += "Policy '$PolicyName' ($count resources): Automatic deployment will be triggered for missing configurations"
                    }
                    'modify' {
                        $guidance += "Policy '$PolicyName' ($count resources): Resource properties will be automatically modified"
                    }
                    default {
                        $guidance += "Policy '$PolicyName' ($count resources): Manual remediation required - effect is '$effect'"
                    }
                }

} catch {
            $guidance += "Policy $PolicyId ($count resources): Unable to retrieve policy details"
        }
    }

    return $guidance
}

Write-Host "`nAzure Policy Compliance Remediation" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
}

$violations = Get-RemediableViolations -PolicyAssignment $PolicyAssignmentName -ResourceGroup $ResourceGroupName -MaxResults $MaxResources -ExcludeTypes $ExcludeResourceTypes

if ($violations.Count -eq 0) {
    Write-Host "No remediable policy violations found!" -ForegroundColor Green
    exit 0
}

$guidance = Get-RemediationGuidance -Violations $violations
Write-Host "`nRemediation Actions:" -ForegroundColor Green
$guidance | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Green
}

if ($DryRun) {
    Show-RemediationSummary -Violations $violations -RemediationTasks @() -IsDryRun $true
    Write-Host "`nDry run completed. Use without -DryRun to execute remediation." -ForegroundColor Green
    exit 0
}

$RemediationTasks = @()

if ($PolicyAssignmentName) {
    $assignment = Get-AzPolicyAssignment -Name $PolicyAssignmentName
    if ($assignment) {
        $task = New-RemediationTask -PolicyAssignment $assignment -Violations $violations -Mode $RemediationMode
        if ($task) { $RemediationTasks += $task }
    }
} else {
    $assignments = Get-PolicyAssignments -ResourceGroup $ResourceGroupName

    foreach ($assignment in $assignments) {
        $AssignmentViolations = $violations | Where-Object { $_.PolicyAssignmentId -eq $assignment.ResourceId }

        if ($AssignmentViolations.Count -gt 0) {
            $task = New-RemediationTask -PolicyAssignment $assignment -Violations $AssignmentViolations -Mode $RemediationMode
            if ($task) { $RemediationTasks += $task }
        }
    }
}

if ($WaitForCompletion -and $RemediationTasks.Count -gt 0) {
    Wait-ForRemediationCompletion -RemediationTasks $RemediationTasks -TimeoutMinutes $TimeoutMinutes
}

Show-RemediationSummary -Violations $violations -RemediationTasks $RemediationTasks -IsDryRun $false

Write-Host "`nRemediation process completed!" -ForegroundColor Green

return @{
    ViolationsFound = $violations.Count
    RemediationTasks = $RemediationTasks
    Guidance = $guidance
}\n



