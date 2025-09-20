<#
.SYNOPSIS
    Security compliance scan

.DESCRIPTION
    Check Azure security assessments and compliance
    Author: Wes Ellis (wes@wesellis.com)#>
param(
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
        # Get security assessments
    $assessments = Get-AzSecurityAssessment -ErrorAction Stop
    # Get policy compliance
    $policyStates = Get-AzPolicyState -ErrorAction Stop
    # Get security score
    $securityScore = Get-AzSecurityScore -ErrorAction Stop
        $complianceReport = @{
        SubscriptionId = (Get-AzContext).Subscription.Id
        SubscriptionName = (Get-AzContext).Subscription.Name
        AssessmentDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SecurityScore = $securityScore
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
            TotalPolicies = $policyStates.Count
            NonCompliant = ($policyStates | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count
            Policies = $policyStates | Group-Object PolicyDefinitionName | ForEach-Object {
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
        $complianceReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "[OK] Compliance report exported to: $OutputPath"
    }
        # Display summary
    Write-Host ""
    Write-Host "                              SECURITY COMPLIANCE REPORT"
    Write-Host ""
    Write-Host "Security Score: $($complianceReport.SecurityScore.SecureScorePercentage)%"
    Write-Host "Compliance Rate: $($complianceReport.ComplianceRate)%"
    Write-Host "Failed Assessments: $($complianceReport.FailedAssessments)/$($complianceReport.TotalAssessments)"
    Write-Host ""
    $highPriorityIssues = $complianceReport.Assessments | Where-Object { $_.Status -eq "Unhealthy" -and $_.Severity -eq "High" }
    if ($highPriorityIssues.Count -gt 0) {
        $highPriorityIssues | ForEach-Object {
            Write-Host "    $($_.Name)"
        }
    } else {
        Write-Host "    No high priority issues found"
    }
    Write-Host ""
    Write-Host "Security compliance scan completed successfully!"
} catch { throw }

