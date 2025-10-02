#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Security compliance scan

.DESCRIPTION
    Check Azure security assessments and compliance
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter()]
    [string]$SubscriptionId,
    [ValidateSet("All", "CIS", "PCI", "SOC2", "ISO27001", "NIST")]
    [string]$ComplianceStandard = "All",
    [ValidateSet("All", "High", "Medium", "Low")]
    [string]$MinimumSeverity = "Medium",
    [Parameter()]
    [switch]$ExportReport,
    [Parameter()]
    [string]$OutputPath = ".\security-compliance-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)
try {
        if (-not (Get-AzContext)) {
        throw "Security modules validation failed"
    }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    $assessments = Get-AzSecurityAssessment -ErrorAction Stop
    $PolicyStates = Get-AzPolicyState -ErrorAction Stop
    $SecurityScore = Get-AzSecurityScore -ErrorAction Stop
        $ComplianceReport = @{
        SubscriptionId = (Get-AzContext).Subscription.Id
        SubscriptionName = (Get-AzContext).Subscription.Name
        AssessmentDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SecurityScore = $SecurityScore
        TotalAssessments = $assessments.Count
        FailedAssessments = ($assessments | Where-Object { $_.Status.Code -eq "Unhealthy" }).Count
        ComplianceRate = [math]::Round((($assessments.Count - ($assessments | Where-Object { $_.Status.Code -eq "Unhealthy" }).Count) / $assessments.Count) * 100, 2)
        Assessments = $assessments | ForEach-Object {
            @{
                Name = $_.DisplayName
                Status = $_.Status.Code
                Severity = $_.Metadata.Severity
                Category = $_.Metadata.Categories
                Description = $_.Status.Description
                RemediationDescription = $_.Metadata.RemediationDescription
            }
        }
        PolicyCompliance = @{
            TotalPolicies = $PolicyStates.Count
            NonCompliant = ($PolicyStates | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count
            Policies = $PolicyStates | Group-Object PolicyDefinitionName | ForEach-Object {
                @{
                    PolicyName = $_.Name
                    TotalResources = $_.Count
                    NonCompliantResources = ($_.Group | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count
                    ComplianceRate = [math]::Round((($_.Count - ($_.Group | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count) / $_.Count) * 100, 2)
                }
            }
        }
    }
        if ($ExportReport) {
        $ComplianceReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "[OK] Compliance report exported to: $OutputPath"
    }
    Write-Output ""
    Write-Output "                              SECURITY COMPLIANCE REPORT"
    Write-Output ""
    Write-Output "Security Score: $($ComplianceReport.SecurityScore.SecureScorePercentage)%"
    Write-Output "Compliance Rate: $($ComplianceReport.ComplianceRate)%"
    Write-Output "Failed Assessments: $($ComplianceReport.FailedAssessments)/$($ComplianceReport.TotalAssessments)"
    Write-Output ""
    $HighPriorityIssues = $ComplianceReport.Assessments | Where-Object { $_.Status -eq "Unhealthy" -and $_.Severity -eq "High" }
    if ($HighPriorityIssues.Count -gt 0) {
        $HighPriorityIssues | ForEach-Object {
            Write-Output "    $($_.Name)"
        }
    } else {
        Write-Output "    No high priority issues found"
    }
    Write-Output ""
    Write-Output "Security compliance scan completed successfully!"
} catch { throw`n}
