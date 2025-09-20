#Requires -Module Az.PolicyInsights
#Requires -Module Az.Resources
#Requires -Version 5.1
<#
.SYNOPSIS
    remediate compliance
.DESCRIPTION
    remediate compliance operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Remediates non-compliant Azure resources based on policy assignments

    Identifies and remediates non-compliant resources by triggering
    remediation tasks for policies that support automatic remediation.
    Supports bulk remediation and monitoring of remediation progress.
.PARAMETER SubscriptionId
    Target subscription for remediation
.PARAMETER PolicyAssignmentName
    Specific policy assignment to remediate
.PARAMETER ResourceGroupName
    Limit remediation to specific resource group
.PARAMETER MaxResources
    Maximum number of resources to remediate at once
.PARAMETER RemediationMode
    Remediation mode: Auto, Manual, Preview
.PARAMETER WaitForCompletion
    Wait for remediation tasks to complete
.PARAMETER TimeoutMinutes
    Timeout for waiting on remediation completion
.PARAMETER ExcludeResourceTypes
    Resource types to exclude from remediation
.PARAMETER DryRun
    Preview remediation actions without executing

    .\remediate-compliance.ps1 -PolicyAssignmentName "audit-vm-backup" -RemediationMode Auto

    Automatically remediate non-compliant VMs for backup policy

    .\remediate-compliance.ps1 -ResourceGroupName "RG-Prod" -DryRun

    Preview remediation actions for production resource group#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$PolicyAssignmentName,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [ValidateRange(1, 500)]
    [int]$MaxResources = 100,

    [Parameter()]
    [ValidateSet('Auto', 'Manual', 'Preview')]
    [string]$RemediationMode = 'Manual',

    [Parameter()]
    [switch]$WaitForCompletion,

    [Parameter()]
    [ValidateRange(1, 480)]
    [int]$TimeoutMinutes = 60,

    [Parameter()]
    [string[]]$ExcludeResourceTypes,

    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Test-AzureConnection {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    return Get-AzContext
}

function Get-RemediableViolations {
    param(
        [string]$PolicyAssignment,
        [string]$ResourceGroup,
        [int]$MaxResults,
        [string[]]$ExcludeTypes
    )

    Write-Host "Finding non-compliant resources..." -ForegroundColor Yellow

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

        # Filter out excluded resource types
        if ($ExcludeTypes) {
            $violations = $violations | Where-Object { $_.ResourceType -notin $ExcludeTypes }
        }

        # Filter to only remediable violations (policies with deployIfNotExists or modify effects)
        $remediableViolations = $violations | Where-Object {
            $policyDef = Get-AzPolicyDefinition -Id $_.PolicyDefinitionId -ErrorAction SilentlyContinue
            if ($policyDef) {
                $effect = $policyDef.Properties.PolicyRule.then.effect
                return $effect -in @('deployIfNotExists', 'modify')
            }
            return $false
        }

        Write-Host "Found $($violations.Count) non-compliant resources, $($remediableViolations.Count) are remediable" -ForegroundColor Cyan

        return $remediableViolations
    }
    catch {
        Write-Error "Failed to retrieve policy violations: $_"
        throw
    }
}

function Get-PolicyAssignments {
    param(
        [string]$ResourceGroup
    )

    try {
        $params = @{}
        if ($ResourceGroup) {
            $params['Scope'] = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroup"
        }

        $assignments = Get-AzPolicyAssignment @params
        return $assignments | Where-Object {
            # Filter to assignments that support remediation
            $policyDef = Get-AzPolicyDefinition -Id $_.Properties.PolicyDefinitionId -ErrorAction SilentlyContinue
            if ($policyDef) {
                $effect = $policyDef.Properties.PolicyRule.then.effect
                return $effect -in @('deployIfNotExists', 'modify')
            }
            return $false
        
} catch {
        Write-Error "Failed to retrieve policy assignments: $_"
        throw
    }
}

function New-RemediationTask {
    param(
        [object]$PolicyAssignment,
        [array]$Violations,
        [string]$Mode
    )

    $assignmentName = $PolicyAssignment.Name
    $remediationName = "remediation-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    Write-Host "Creating remediation task for: $assignmentName" -ForegroundColor Yellow

    try {
        if ($PSCmdlet.ShouldProcess($assignmentName, "Create remediation task")) {
            $params = @{
                Name = $remediationName
                PolicyAssignmentId = $PolicyAssignment.ResourceId
                Scope = $PolicyAssignment.Properties.Scope
            }

            # Limit to specific resources if we have a small set
            if ($Violations.Count -le 50) {
                $resourceIds = $Violations | Select-Object -ExpandProperty ResourceId
                $params['ResourceIdentifier'] = $resourceIds
            }

            $remediation = Start-AzPolicyRemediation @params

            Write-Host "Remediation task created: $remediationName" -ForegroundColor Green
            Write-Host "Task ID: $($remediation.Id)" -ForegroundColor Cyan
            Write-Host "Resources to remediate: $($Violations.Count)" -ForegroundColor Cyan

            return $remediation
        
} catch {
        Write-Error "Failed to create remediation task for $assignmentName : $_"
        return $null
    }
}

function Wait-ForRemediationCompletion {
    param(
        [array]$RemediationTasks,
        [int]$TimeoutMinutes
    )

    if ($RemediationTasks.Count -eq 0) {
        return
    }

    Write-Host "Monitoring remediation progress..." -ForegroundColor Yellow
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)

    do {
        $allCompleted = $true
        $inProgress = 0
        $completed = 0
        $failed = 0

        foreach ($task in $RemediationTasks) {
            try {
                $status = Get-AzPolicyRemediation -Name $task.Name -Scope $task.Properties.Scope

                switch ($status.Properties.ProvisioningState) {
                    'Succeeded' { $completed++ }
                    'Failed' { $failed++; $allCompleted = $false }
                    'Canceled' { $failed++; $allCompleted = $false }
                    default { $inProgress++; $allCompleted = $false }
                
} catch {
                Write-Warning "Could not get status for remediation task: $($task.Name)"
                $allCompleted = $false
            }
        }

        Write-Host "Remediation Status - Completed: $completed, In Progress: $inProgress, Failed: $failed" -ForegroundColor Cyan

        if (-not $allCompleted -and (Get-Date) -lt $timeout) {
            Start-Sleep -Seconds 30
        }
    } while (-not $allCompleted -and (Get-Date) -lt $timeout)

    if ($allCompleted) {
        Write-Host "All remediation tasks completed!" -ForegroundColor Green
    } else {
        Write-Warning "Remediation tasks did not complete within the timeout period"
    }
}

function Show-RemediationSummary {
    param(
        [array]$Violations,
        [array]$RemediationTasks,
        [bool]$IsDryRun
    )

    Write-Host "`nRemediation Summary" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan

    if ($IsDryRun) {
        Write-Host "DRY RUN - No actual remediation performed" -ForegroundColor Yellow
    }

    Write-Host "Non-compliant resources found: $($Violations.Count)"
    Write-Host "Remediation tasks created: $($RemediationTasks.Count)"

    if ($Violations.Count -gt 0) {
        Write-Host "`nViolations by Resource Type:" -ForegroundColor Cyan
        $Violations | Group-Object ResourceType | Sort-Object Count -Descending | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count)"
        }

        Write-Host "`nViolations by Policy:" -ForegroundColor Cyan
        $Violations | Group-Object PolicyDefinitionId | Sort-Object Count -Descending | ForEach-Object {
            $policyName = ($_.Name -split '/')[-1]
            Write-Host "  $policyName : $($_.Count)"
        }
    }

    if ($RemediationTasks.Count -gt 0) {
        Write-Host "`nRemediation Tasks:" -ForegroundColor Cyan
        $RemediationTasks | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Green
        }
    }
}

function Get-RemediationGuidance {
    param([array]$Violations)

    $guidance = @()

    # Group violations by policy to provide specific guidance
    $policyGroups = $Violations | Group-Object PolicyDefinitionId

    foreach ($group in $policyGroups) {
        $policyId = $group.Name
        $count = $group.Count

        try {
            $policyDef = Get-AzPolicyDefinition -Id $policyId -ErrorAction SilentlyContinue
            if ($policyDef) {
                $policyName = $policyDef.Properties.DisplayName
                $effect = $policyDef.Properties.PolicyRule.then.effect

                switch ($effect) {
                    'deployIfNotExists' {
                        $guidance += "Policy '$policyName' ($count resources): Automatic deployment will be triggered for missing configurations"
                    }
                    'modify' {
                        $guidance += "Policy '$policyName' ($count resources): Resource properties will be automatically modified"
                    }
                    default {
                        $guidance += "Policy '$policyName' ($count resources): Manual remediation required - effect is '$effect'"
                    }
                }
            
} catch {
            $guidance += "Policy $policyId ($count resources): Unable to retrieve policy details"
        }
    }

    return $guidance
}

# Main execution
Write-Host "`nAzure Policy Compliance Remediation" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

# Set subscription context if provided
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
}

# Find non-compliant resources
$violations = Get-RemediableViolations -PolicyAssignment $PolicyAssignmentName -ResourceGroup $ResourceGroupName -MaxResults $MaxResources -ExcludeTypes $ExcludeResourceTypes

if ($violations.Count -eq 0) {
    Write-Host "No remediable policy violations found!" -ForegroundColor Green
    exit 0
}

# Get remediation guidance
$guidance = Get-RemediationGuidance -Violations $violations
Write-Host "`nRemediation Actions:" -ForegroundColor Cyan
$guidance | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Yellow
}

# If this is a dry run, show summary and exit
if ($DryRun) {
    Show-RemediationSummary -Violations $violations -RemediationTasks @() -IsDryRun $true
    Write-Host "`nDry run completed. Use without -DryRun to execute remediation." -ForegroundColor Yellow
    exit 0
}

# Create remediation tasks
$remediationTasks = @()

if ($PolicyAssignmentName) {
    # Remediate specific policy assignment
    $assignment = Get-AzPolicyAssignment -Name $PolicyAssignmentName
    if ($assignment) {
        $task = New-RemediationTask -PolicyAssignment $assignment -Violations $violations -Mode $RemediationMode
        if ($task) { $remediationTasks += $task }
    }
} else {
    # Get all policy assignments that need remediation
    $assignments = Get-PolicyAssignments -ResourceGroup $ResourceGroupName

    foreach ($assignment in $assignments) {
        $assignmentViolations = $violations | Where-Object { $_.PolicyAssignmentId -eq $assignment.ResourceId }

        if ($assignmentViolations.Count -gt 0) {
            $task = New-RemediationTask -PolicyAssignment $assignment -Violations $assignmentViolations -Mode $RemediationMode
            if ($task) { $remediationTasks += $task }
        }
    }
}

# Wait for completion if requested
if ($WaitForCompletion -and $remediationTasks.Count -gt 0) {
    Wait-ForRemediationCompletion -RemediationTasks $remediationTasks -TimeoutMinutes $TimeoutMinutes
}

# Show summary
Show-RemediationSummary -Violations $violations -RemediationTasks $remediationTasks -IsDryRun $false

Write-Host "`nRemediation process completed!" -ForegroundColor Green

# Return results
return @{
    ViolationsFound = $violations.Count
    RemediationTasks = $remediationTasks
    Guidance = $guidance
}\n