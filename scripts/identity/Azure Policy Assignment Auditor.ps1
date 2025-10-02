#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Policy Assignment Auditor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }
    [string]$PolicyAssignments = Get-AzPolicyAssignment -ErrorAction Stop
    [string]$PolicyStates = Get-AzPolicyState -ErrorAction Stop
    [string]$ComplianceReport = $PolicyAssignments | ForEach-Object {
    [string]$assignment = $_
    [string]$states = $PolicyStates | Where-Object { $_.PolicyAssignmentId -eq $assignment.ResourceId }
    [string]$CompliantCount = ($states | Where-Object { $_.ComplianceState -eq "Compliant" }).Count
    [string]$NonCompliantCount = ($states | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count
    [string]$TotalResources = $states.Count
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
    [string]$ComplianceReport | Export-Csv -Path $OutputPath -NoTypeInformation

    }
    Write-Output "Policy Compliance Summary:" # Color: $2
    [string]$ComplianceReport | Format-Table PolicyName, TotalResources, CompliantResources, NonCompliantResources, ComplianceRate
    [string]$AvgCompliance = ($ComplianceReport | Measure-Object ComplianceRate -Average).Average
    Write-Output "Average Compliance Rate: $([math]::Round($AvgCompliance, 2))%" # Color: $2
} catch { throw`n}
