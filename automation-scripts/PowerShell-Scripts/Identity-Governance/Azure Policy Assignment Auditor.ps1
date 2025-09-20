#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Policy Assignment Auditor

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PolicyName,
    [Parameter()]
    [ValidateSet("All" , "Compliant" , "NonCompliant" )]
    [string]$ComplianceState = "All" ,
    [Parameter()]
    [switch]$ExportReport,
    [Parameter()]
    [string]$OutputPath = " .\policy-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
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

    }
    Write-Host "Policy Compliance Summary:" -ForegroundColor Cyan
    $complianceReport | Format-Table PolicyName, TotalResources, CompliantResources, NonCompliantResources, ComplianceRate
$avgCompliance = ($complianceReport | Measure-Object ComplianceRate -Average).Average
    Write-Host "Average Compliance Rate: $([math]::Round($avgCompliance, 2))%" -ForegroundColor Green
} catch { throw }\n

