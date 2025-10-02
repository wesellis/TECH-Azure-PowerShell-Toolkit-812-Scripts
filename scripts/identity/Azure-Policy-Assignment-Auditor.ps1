#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
try {
    if (-not (Get-AzContext) {
        throw "Azure connection validation failed"
    }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }
    $PolicyAssignments = Get-AzPolicyAssignment -ErrorAction Stop
    $PolicyStates = Get-AzPolicyState -ErrorAction Stop
    $ComplianceReport = $PolicyAssignments | ForEach-Object {
        $assignment = $_
        $states = $PolicyStates | Where-Object { $_.PolicyAssignmentId -eq $assignment.ResourceId }
        $CompliantCount = ($states | Where-Object { $_.ComplianceState -eq "Compliant" }).Count
        $NonCompliantCount = ($states | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count
        $TotalResources = $states.Count
        [PSCustomObject]@{
            PolicyName = $assignment.Properties.DisplayName
            AssignmentId = $assignment.ResourceId
            Scope = $assignment.Properties.Scope
            TotalResources = $TotalResources
            CompliantResources = $CompliantCount
            NonCompliantResources = $NonCompliantCount
            ComplianceRate = if ($TotalResources -gt 0) { [math]::Round(($CompliantCount / $TotalResources) * 100, 2) } else { 0 }
        }
    }
    if ($ExportReport) {
        $ComplianceReport | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Output "[OK] Policy audit report exported to: $OutputPath"
    }
    Write-Output "Policy Compliance Summary:"
    $ComplianceReport | Format-Table PolicyName, TotalResources, CompliantResources, NonCompliantResources, ComplianceRate
    $AvgCompliance = ($ComplianceReport | Measure-Object ComplianceRate -Average).Average
    Write-Output "Average Compliance Rate: $([math]::Round($AvgCompliance, 2))%"
} catch { throw`n}
