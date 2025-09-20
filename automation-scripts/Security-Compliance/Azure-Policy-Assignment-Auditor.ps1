<#
.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Policy Assignment Auditor
# Audit policy assignments and compliance across subscriptions
param(
    [Parameter()]
    [string]$SubscriptionId,
    [Parameter()]
    [string]$PolicyName,
    [ValidateSet("All", "Compliant", "NonCompliant")]
    [string]$ComplianceState = "All",
    [Parameter()]
    [switch]$ExportReport,
    [Parameter()]
    [string]$OutputPath = ".\policy-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)
# Azure script
try {
    if (-not (Get-AzContext) {
        throw "Azure connection validation failed"
    }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }
    $policyAssignments = Get-AzPolicyAssignment -ErrorAction Stop
    $policyStates = Get-AzPolicyState -ErrorAction Stop
    $complianceReport = $policyAssignments | ForEach-Object {
        $assignment = $_
        $states = $policyStates | Where-Object { $_.PolicyAssignmentId -eq $assignment.ResourceId }
        $compliantCount = ($states | Where-Object { $_.ComplianceState -eq "Compliant" }).Count
        $nonCompliantCount = ($states | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count
        $totalResources = $states.Count
        [PSCustomObject]@{
            PolicyName = $assignment.Properties.DisplayName
            AssignmentId = $assignment.ResourceId
            Scope = $assignment.Properties.Scope
            TotalResources = $totalResources
            CompliantResources = $compliantCount
            NonCompliantResources = $nonCompliantCount
            ComplianceRate = if ($totalResources -gt 0) { [math]::Round(($compliantCount / $totalResources) * 100, 2) } else { 0 }
        }
    }
    if ($ExportReport) {
        $complianceReport | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Host "[OK] Policy audit report exported to: $OutputPath"
    }
    Write-Host "Policy Compliance Summary:"
    $complianceReport | Format-Table PolicyName, TotalResources, CompliantResources, NonCompliantResources, ComplianceRate
    $avgCompliance = ($complianceReport | Measure-Object ComplianceRate -Average).Average
    Write-Host "Average Compliance Rate: $([math]::Round($avgCompliance, 2))%"
} catch { throw }

