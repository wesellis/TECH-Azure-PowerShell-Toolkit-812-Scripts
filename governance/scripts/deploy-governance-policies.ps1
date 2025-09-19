#Requires -Module Az.Resources
#Requires -Module Az.Profile
#Requires -Version 5.1

<#
.SYNOPSIS
    Deploys governance policies and initiatives to Azure subscriptions

.DESCRIPTION
    Automates the deployment of common Azure governance policies including
    tagging requirements, resource location restrictions, and security policies.
    Supports custom policy definitions and built-in policies.

.PARAMETER ManagementGroup
    Management group scope for policy assignment

.PARAMETER SubscriptionId
    Subscription ID for policy assignment (uses current context if not specified)

.PARAMETER ResourceGroupName
    Resource group scope for policy assignment

.PARAMETER PolicySetName
    Name of the policy set to deploy (Default, Security, Tagging, Location)

.PARAMETER CustomPolicyPath
    Path to custom policy definition JSON file

.PARAMETER AssignmentName
    Name for the policy assignment

.PARAMETER ExcludedScopes
    Array of resource IDs to exclude from policy assignment

.PARAMETER EnforcementMode
    Policy enforcement mode: Default, DoNotEnforce

.PARAMETER WhatIf
    Show what would be deployed without making changes

.EXAMPLE
    .\deploy-governance-policies.ps1 -PolicySetName "Security" -EnforcementMode "Default"

    Deploys security policy set to current subscription

.EXAMPLE
    .\deploy-governance-policies.ps1 -CustomPolicyPath ".\custom-policy.json" -ResourceGroupName "RG-Test"

    Deploys custom policy to specific resource group

.NOTES
    Version: 1.0.0
    Created: 2024-11-15
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ManagementGroup,

    [Parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [ValidateSet('Default', 'Security', 'Tagging', 'Location', 'Monitoring')]
    [string]$PolicySetName = 'Default',

    [Parameter()]
    [ValidateScript({
        if (Test-Path $_) { $true }
        else { throw "Policy file not found: $_" }
    })]
    [string]$CustomPolicyPath,

    [Parameter()]
    [string]$AssignmentName,

    [Parameter()]
    [string[]]$ExcludedScopes,

    [Parameter()]
    [ValidateSet('Default', 'DoNotEnforce')]
    [string]$EnforcementMode = 'Default'
)

$ErrorActionPreference = 'Stop'

function Test-AzureConnection {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
        $context = Get-AzContext
    }

    if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
        Write-Host "Switching to subscription: $SubscriptionId" -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }

    return $context
}

function Get-PolicyDefinitions {
    param([string]$SetName)

    $policies = @{
        'Default' = @(
            'Require a tag and its value on resources',
            'Allowed locations',
            'Not allowed resource types'
        )
        'Security' = @(
            'Deploy default Microsoft IaaSAntimalware extension for Windows Server',
            'Audit VMs that do not use managed disks',
            'Require SQL Server 12.0',
            'Storage accounts should restrict network access'
        )
        'Tagging' = @(
            'Require a tag and its value on resources',
            'Inherit a tag from the resource group if missing',
            'Add or replace a tag on resources'
        )
        'Location' = @(
            'Allowed locations',
            'Allowed locations for resource groups'
        )
        'Monitoring' = @(
            'Deploy Log Analytics agent for Windows VMs',
            'Deploy Log Analytics agent for Linux VMs',
            'Audit diagnostic setting'
        )
    }

    return $policies[$SetName]
}

function Get-PolicyScope {
    if ($ManagementGroup) {
        return "/providers/Microsoft.Management/managementGroups/$ManagementGroup"
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

function New-PolicyFromFile {
    param(
        [string]$FilePath,
        [string]$Scope
    )

    try {
        $policyContent = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

        $params = @{
            Name = $policyContent.name
            DisplayName = $policyContent.properties.displayName
            Description = $policyContent.properties.description
            Policy = ($policyContent.properties.policyRule | ConvertTo-Json -Depth 10)
            Parameter = if ($policyContent.properties.parameters) {
                ($policyContent.properties.parameters | ConvertTo-Json -Depth 10)
            } else { $null }
            ManagementGroupName = if ($ManagementGroup) { $ManagementGroup } else { $null }
            SubscriptionId = if (-not $ManagementGroup -and -not $ResourceGroupName) {
                (Get-AzContext).Subscription.Id
            } else { $null }
        }

        if ($PSCmdlet.ShouldProcess($policyContent.name, "Create policy definition")) {
            $definition = New-AzPolicyDefinition @params
            Write-Host "Created policy definition: $($definition.Name)" -ForegroundColor Green
            return $definition
        }
    }
    catch {
        Write-Error "Failed to create policy from file: $_"
        throw
    }
}

function New-PolicyAssignments {
    param(
        [array]$PolicyNames,
        [string]$Scope,
        [string]$AssignmentName
    )

    $assignments = @()

    foreach ($policyName in $PolicyNames) {
        try {
            # Try to find built-in policy first
            $definition = Get-AzPolicyDefinition | Where-Object { $_.Properties.DisplayName -eq $policyName }

            if (-not $definition) {
                Write-Warning "Policy not found: $policyName"
                continue
            }

            $assignmentParams = @{
                Name = "$AssignmentName-$($definition.Name)".Substring(0, [Math]::Min(64, "$AssignmentName-$($definition.Name)".Length))
                DisplayName = "Governance: $policyName"
                Scope = $Scope
                PolicyDefinition = $definition
                EnforcementMode = $EnforcementMode
            }

            if ($ExcludedScopes) {
                $assignmentParams['NotScope'] = $ExcludedScopes
            }

            if ($PSCmdlet.ShouldProcess($policyName, "Assign policy")) {
                $assignment = New-AzPolicyAssignment @assignmentParams
                $assignments += $assignment
                Write-Host "Assigned policy: $policyName" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Failed to assign policy '$policyName': $_"
        }
    }

    return $assignments
}

function Show-DeploymentSummary {
    param(
        [array]$Assignments,
        [string]$Scope
    )

    Write-Host "`nDeployment Summary:" -ForegroundColor Cyan
    Write-Host "  Scope: $Scope"
    Write-Host "  Enforcement Mode: $EnforcementMode"
    Write-Host "  Policies Assigned: $($Assignments.Count)"

    if ($ExcludedScopes) {
        Write-Host "  Excluded Scopes: $($ExcludedScopes.Count)"
    }

    Write-Host "`nAssigned Policies:" -ForegroundColor Cyan
    $Assignments | ForEach-Object {
        Write-Host "  - $($_.Properties.DisplayName)" -ForegroundColor Green
    }
}

# Main execution
Write-Host "`nGovernance Policy Deployment" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

$scope = Get-PolicyScope
Write-Host "Target scope: $scope" -ForegroundColor Yellow

if (-not $AssignmentName) {
    $AssignmentName = "Governance-$(Get-Date -Format 'yyyyMMdd')"
}

$assignments = @()

if ($CustomPolicyPath) {
    Write-Host "`nDeploying custom policy..." -ForegroundColor Yellow
    $customDefinition = New-PolicyFromFile -FilePath $CustomPolicyPath -Scope $scope

    if ($customDefinition) {
        $assignmentParams = @{
            Name = $AssignmentName
            DisplayName = "Custom: $($customDefinition.Properties.DisplayName)"
            Scope = $scope
            PolicyDefinition = $customDefinition
            EnforcementMode = $EnforcementMode
        }

        if ($ExcludedScopes) {
            $assignmentParams['NotScope'] = $ExcludedScopes
        }

        if ($PSCmdlet.ShouldProcess($customDefinition.Name, "Assign custom policy")) {
            $assignments += New-AzPolicyAssignment @assignmentParams
        }
    }
}
else {
    Write-Host "`nDeploying $PolicySetName policy set..." -ForegroundColor Yellow
    $policyNames = Get-PolicyDefinitions -SetName $PolicySetName

    if ($policyNames) {
        $assignments = New-PolicyAssignments -PolicyNames $policyNames -Scope $scope -AssignmentName $AssignmentName
    }
    else {
        Write-Warning "No policies found for set: $PolicySetName"
    }
}

if ($assignments.Count -gt 0) {
    Show-DeploymentSummary -Assignments $assignments -Scope $scope
    Write-Host "`nPolicy deployment completed successfully!" -ForegroundColor Green
}
else {
    Write-Warning "No policies were deployed"
}