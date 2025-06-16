# Azure Policy Assignment Auditor
# Audit policy assignments and compliance across subscriptions
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$PolicyName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "Compliant", "NonCompliant")]
    [string]$ComplianceState = "All",
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportReport,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\policy-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Policy Assignment Auditor" -Version "1.0" -Description "Audit policy compliance and assignments"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.PolicyInsights'))) {
        throw "Azure connection validation failed"
    }

    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }

    $policyAssignments = Get-AzPolicyAssignment
    $policyStates = Get-AzPolicyState
    
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
        Write-Log "✓ Policy audit report exported to: $OutputPath" -Level SUCCESS
    }

    Write-Host "Policy Compliance Summary:" -ForegroundColor Cyan
    $complianceReport | Format-Table PolicyName, TotalResources, CompliantResources, NonCompliantResources, ComplianceRate
    
    $avgCompliance = ($complianceReport | Measure-Object ComplianceRate -Average).Average
    Write-Host "Average Compliance Rate: $([math]::Round($avgCompliance, 2))%" -ForegroundColor Green

} catch {
    Write-Log "❌ Policy audit failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
