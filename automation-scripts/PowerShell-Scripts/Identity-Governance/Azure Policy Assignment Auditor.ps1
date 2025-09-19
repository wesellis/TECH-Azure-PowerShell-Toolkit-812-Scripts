#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Policy Assignment Auditor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Policy Assignment Auditor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPolicyName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" All" , " Compliant" , " NonCompliant" )]
    [string]$WEComplianceState = " All" ,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEExportReport,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " .\policy-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName " Azure Policy Assignment Auditor" -Version " 1.0" -Description " Audit policy compliance and assignments"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.PolicyInsights'))) {
        throw " Azure connection validation failed"
    }

    if ($WESubscriptionId) { Set-AzContext -SubscriptionId $WESubscriptionId }

    $policyAssignments = Get-AzPolicyAssignment -ErrorAction Stop
    $policyStates = Get-AzPolicyState -ErrorAction Stop
    
    $complianceReport = $policyAssignments | ForEach-Object {
        $assignment = $_
        $states = $policyStates | Where-Object { $_.PolicyAssignmentId -eq $assignment.ResourceId }
        
        $compliantCount = ($states | Where-Object { $_.ComplianceState -eq " Compliant" }).Count
        $nonCompliantCount = ($states | Where-Object { $_.ComplianceState -eq " NonCompliant" }).Count
       ;  $totalResources = $states.Count
        
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

    if ($WEExportReport) {
        $complianceReport | Export-Csv -Path $WEOutputPath -NoTypeInformation
        Write-Log " [OK] Policy audit report exported to: $WEOutputPath" -Level SUCCESS
    }

    Write-WELog " Policy Compliance Summary:" " INFO" -ForegroundColor Cyan
    $complianceReport | Format-Table PolicyName, TotalResources, CompliantResources, NonCompliantResources, ComplianceRate
    
   ;  $avgCompliance = ($complianceReport | Measure-Object ComplianceRate -Average).Average
    Write-WELog " Average Compliance Rate: $([math]::Round($avgCompliance, 2))%" " INFO" -ForegroundColor Green

} catch {
    Write-Log "  Policy audit failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
