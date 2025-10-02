#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Deploys governance policies and initiatives to Azure subscriptions

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Automates the deployment of common Azure governance policies including
    tagging requirements, resource location restrictions, and security policies.
    Supports custom policy definitions and built-in policies.
.parameter ManagementGroup
    Management group scope for policy assignment
.parameter SubscriptionId
    Subscription ID for policy assignment (uses current context if not specified)
.parameter ResourceGroupName
    Resource group scope for policy assignment
.parameter PolicySetName
    Name of the policy set to deploy (Default, Security, Tagging, Location)
.parameter CustomPolicyPath
    Path to custom policy definition JSON file
.parameter AssignmentName
    Name for the policy assignment
.parameter ExcludedScopes
    Array of resource IDs to exclude from policy assignment
.parameter EnforcementMode
    Policy enforcement mode: Default, DoNotEnforce
.parameter WhatIf
    Show what would be deployed without making changes

    .\deploy-governance-policies.ps1 -PolicySetName "Security" -EnforcementMode "Default"

    Deploys security policy set to current subscription

    .\deploy-governance-policies.ps1 -CustomPolicyPath ".\custom-policy.json" -ResourceGroupName "RG-Test"

    Deploys custom policy to specific resource group
.NOTES

[parameter()]
    [string]$ManagementGroup,

    [parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [parameter()]
    [string]$ResourceGroupName,

    [parameter()]
    [ValidateSet('Default', 'Security', 'Tagging', 'Location', 'Monitoring')]
    [string]$PolicySetName = 'Default',

    [parameter()]
    [ValidateScript({
        if (Test-Path $_) { $true }
        else { throw "Policy file not found: $_" }
    })]
    [string]$CustomPolicyPath,

    [parameter()]
    [string]$AssignmentName,

    [parameter()]
    [string[]]$ExcludedScopes,

    [parameter()]
    [ValidateSet('Default', 'DoNotEnforce')]
    [string]$EnforcementMode = 'Default'
)

$ErrorActionPreference = 'Stop'

[OutputType([string])] 
 {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
        $context = Get-AzContext
    }

    if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
        Write-Host "Switching to subscription: $SubscriptionId" -ForegroundColor Green
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }

    return $context
}

function Get-PolicyDefinitions {
    [string]$SetName)

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
    [string]$FilePath,
        [string]$Scope
    )

    try {
        $PolicyContent = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

        $params = @{
            Name = $PolicyContent.name
            DisplayName = $PolicyContent.properties.displayName
            Description = $PolicyContent.properties.description
            Policy = ($PolicyContent.properties.policyRule | ConvertTo-Json -Depth 10)
            parameter = if ($PolicyContent.properties.parameters) {
                ($PolicyContent.properties.parameters | ConvertTo-Json -Depth 10)
            } else { $null }
            ManagementGroupName = if ($ManagementGroup) { $ManagementGroup } else { $null }
            SubscriptionId = if (-not $ManagementGroup -and -not $ResourceGroupName) {
                (Get-AzContext).Subscription.Id
            } else { $null }
        }

        if ($PSCmdlet.ShouldProcess($PolicyContent.name, "Create policy definition")) {
            $definition = New-AzPolicyDefinition @params
            Write-Host "Created policy definition: $($definition.Name)" -ForegroundColor Green
            return $definition
        }
    } catch {
        write-Error "Failed to create policy from file: $_"
        throw
    }
}

function New-PolicyAssignments {
    [array]$PolicyNames,
        [string]$Scope,
        [string]$AssignmentName
    )

    $assignments = @()

    foreach ($PolicyName in $PolicyNames) {
        try {
            $definition = Get-AzPolicyDefinition | Where-Object { $_.Properties.DisplayName -eq $PolicyName }

            if (-not $definition) {
                write-Warning "Policy not found: $PolicyName"
                continue
            }

            $AssignmentParams = @{
                Name = "$AssignmentName-$($definition.Name)".Substring(0, [Math]::Min(64, "$AssignmentName-$($definition.Name)".length))
                DisplayName = "Governance: $PolicyName"
                Scope = $Scope
                PolicyDefinition = $definition
                EnforcementMode = $EnforcementMode
            }

            if ($ExcludedScopes) {
                $AssignmentParams['NotScope'] = $ExcludedScopes
            }

            if ($PSCmdlet.ShouldProcess($PolicyName, "Assign policy")) {
                $assignment = New-AzPolicyAssignment @assignmentParams
                $assignments += $assignment
                Write-Host "Assigned policy: $PolicyName" -ForegroundColor Green
            }
        } catch {
            write-Warning "Failed to assign policy '$PolicyName': $_"
        }
    }

    return $assignments
}

function Show-DeploymentSummary {
    [array]$Assignments,
        [string]$Scope
    )

    Write-Host "`nDeployment Summary:" -ForegroundColor Green
    Write-Output "Scope: $Scope"
    Write-Output "Enforcement Mode: $EnforcementMode"
    Write-Output "Policies Assigned: $($Assignments.Count)"

    if ($ExcludedScopes) {
        Write-Output "Excluded Scopes: $($ExcludedScopes.Count)"
    }

    Write-Host "`nAssigned Policies:" -ForegroundColor Green
    $Assignments | ForEach-Object {
        Write-Host "  - $($_.Properties.DisplayName)" -ForegroundColor Green
    }
}

Write-Host "`nGovernance Policy Deployment" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

$scope = Get-PolicyScope
Write-Host "Target scope: $scope" -ForegroundColor Green

if (-not $AssignmentName) {
    $AssignmentName = "Governance-$(Get-Date -Format 'yyyyMMdd')"
}

$assignments = @()

if ($CustomPolicyPath) {
    Write-Host "`nDeploying custom policy..." -ForegroundColor Green
    $CustomDefinition = New-PolicyFromFile -FilePath $CustomPolicyPath -Scope $scope

    if ($CustomDefinition) {
        $AssignmentParams = @{
            Name = $AssignmentName
            DisplayName = "Custom: $($CustomDefinition.Properties.DisplayName)"
            Scope = $scope
            PolicyDefinition = $CustomDefinition
            EnforcementMode = $EnforcementMode
        }

        if ($ExcludedScopes) {
            $AssignmentParams['NotScope'] = $ExcludedScopes
        }

        if ($PSCmdlet.ShouldProcess($CustomDefinition.Name, "Assign custom policy")) {
            $assignments += New-AzPolicyAssignment @assignmentParams
        }
    }
}
else {
    Write-Host "`nDeploying $PolicySetName policy set..." -ForegroundColor Green
    $PolicyNames = Get-PolicyDefinitions -SetName $PolicySetName

    if ($PolicyNames) {
        $assignments = New-PolicyAssignments -PolicyNames $PolicyNames -Scope $scope -AssignmentName $AssignmentName
    }
    else {
        write-Warning "No policies found for set: $PolicySetName"
    }
}

if ($assignments.Count -gt 0) {
    Show-DeploymentSummary -Assignments $assignments -Scope $scope
    Write-Host "`nPolicy deployment completed successfully!" -ForegroundColor Green
}
else {
    write-Warning "No policies were deployed"
}\n



