# Az.Security.Enterprise Module

Enterprise-grade Azure Security management module with comprehensive security automation capabilities.

## Features

### 🛡️ Security Center Automation
- Advanced Security Center configuration
- Multi-tier pricing management
- Auto-provisioning setup
- Security contact configuration
- Workspace integration
- JIT VM access automation

### 🔒 Defender for Cloud Integration
- Comprehensive Defender plan management
- Coverage reporting across all resource types
- Extension configuration
- Sub-plan management
- Automated security assessments

### 📜 Security Policy Enforcement
- Framework-based policy deployment (CIS, NIST, ISO27001, SOC2, PCI-DSS, HIPAA)
- Custom policy set creation
- Compliance testing and reporting
- Policy assignment automation
- Enforcement mode configuration

### 🔍 Vulnerability Assessment
- Multi-resource vulnerability scanning
- Automated remediation capabilities
- Severity-based prioritization
- Executive and technical reporting
- Container image scanning
- Database vulnerability assessment

### 📊 Compliance Score Tracking
- Secure score monitoring
- Target setting and tracking
- Trend analysis
- Control breakdown
- Milestone management
- Progress notifications

### 💡 Security Recommendation Processing
- Prioritized recommendation lists
- Impact and effort analysis
- Automated implementation
- Approval workflows
- Quick win identification
- Implementation tracking

## Installation

```powershell
# Install from PowerShell Gallery (when published)
Install-Module -Name Az.Security.Enterprise -Scope CurrentUser

# Or install from source
Import-Module .\Az.Security.Enterprise.psd1
```

## Quick Start

### Enable Security Center

```powershell
# Basic Security Center setup
Enable-AzSecurityCenterAdvanced -SubscriptionId $subscriptionId `
    -Tier "Standard" `
    -EnableAutoProvisioning

# Advanced configuration with notifications
Enable-AzSecurityCenterAdvanced -SubscriptionId $subscriptionId `
    -Tier "Standard" `
    -EnableAutoProvisioning `
    -SecurityContactEmails @("security@company.com", "it-ops@company.com") `
    -SecurityContactPhone "+1-555-0123" `
    -AlertNotifications "On" `
    -AlertsToAdmins "On" `
    -WorkspaceSettings @{
        WorkspaceId = "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/workspace"
    }
```

### Configure Defender Plans

```powershell
# Enable Defender for VMs with extensions
Set-AzDefenderPlan -PlanName "VirtualMachines" `
    -Enable `
    -SubPlan "P2" `
    -Extensions @{
        "MdeDesignatedSubscription" = @{
            "isEnabled" = "true"
        }
        "AgentlessVmScanning" = @{
            "isEnabled" = "true"
            "configuration" = @{
                "scanningMode" = "Default"
            }
        }
    }

# Enable multiple Defender plans
$defenderPlans = @("VirtualMachines", "SqlServers", "AppServices", "KeyVaults", "StorageAccounts")
foreach ($plan in $defenderPlans) {
    Set-AzDefenderPlan -PlanName $plan -Enable
}

# Get coverage report
$coverage = Get-AzDefenderCoverage -IncludeRecommendations
Write-Host "Defender Coverage: $($coverage.CoveragePercentage)%"
$coverage.Plans | Format-Table Name, Tier, Enabled
```

### Deploy Security Policies

```powershell
# Deploy CIS security baseline
New-AzSecurityPolicySet -PolicySetName "CIS-SecurityBaseline" `
    -Framework "CIS" `
    -SubscriptionId $subscriptionId `
    -EnforcementMode "Default"

# Deploy NIST framework with parameters
$policyParams = @{
    "allowedLocations" = @("eastus", "westus")
    "requiredTags" = @("Environment", "Owner", "CostCenter")
}

New-AzSecurityPolicySet -PolicySetName "NIST-Compliance" `
    -Framework "NIST" `
    -ManagementGroupId "EnterpriseRootMG" `
    -PolicyParameters $policyParams `
    -Metadata @{
        "version" = "1.0"
        "author" = "Security Team"
    }

# Test compliance
$compliance = Test-AzSecurityCompliance -PolicySetName "CIS-SecurityBaseline" `
    -Detailed

Write-Host "Compliance: $($compliance.OverallCompliance) ($($compliance.CompliancePercentage)%)"
```

### Vulnerability Assessment

```powershell
# Scan all VMs in a resource group
$scanResults = Start-AzVulnerabilityAssessment -ResourceType "VirtualMachines" `
    -ResourceGroupName "Production-RG" `
    -ScanType "Full" `
    -EnableAutoRemediation

# Scan specific SQL database
Start-AzVulnerabilityAssessment -ResourceType "SqlDatabases" `
    -ResourceGroupName "Data-RG" `
    -ResourceName "ProductionDB" `
    -ScanType "Quick"

# Generate vulnerability report
$report = Get-AzVulnerabilityReport -ResourceGroupName "Production-RG" `
    -ReportType "Detailed" `
    -IncludeRemediation `
    -OutputPath ".\VulnerabilityReport.json"

Write-Host "Critical vulnerabilities: $($report.VulnerabilityStats.Critical)"
Write-Host "High vulnerabilities: $($report.VulnerabilityStats.High)"

# Executive report
Get-AzVulnerabilityReport -ReportType "Executive" `
    -OutputPath ".\ExecutiveVulnReport.md"
```

### Security Score Management

```powershell
# Get current security score with details
$score = Get-AzSecurityScore -IncludeControls -IncludeRecommendations

Write-Host "Current Security Score: $($score.CurrentScore)/$($score.MaxScore) ($($score.Percentage)%)"

# Display control breakdown
$score.Controls | Sort-Object Percentage | Format-Table DisplayName, CurrentScore, MaxScore, Percentage

# Set security score target
$target = Set-AzSecurityScoreTarget -TargetScore 85 `
    -TargetDate (Get-Date).AddMonths(6) `
    -FocusAreas @("IdentityAndAccess", "DataProtection", "NetworkSecurity") `
    -NotificationEmail "security@company.com" `
    -EnableTracking

# View milestones
$target.Milestones | Format-Table Date, TargetScore, Status
```

### Security Recommendations

```powershell
# Get prioritized recommendations
$recommendations = Get-AzSecurityRecommendations -Severity "High" `
    -Category "QuickWins" `
    -IncludeImplementationSteps

# Display top 10 recommendations
$recommendations | Select-Object -First 10 | Format-Table Name, Severity, Impact, Effort, Priority

# Implement a recommendation
$result = Invoke-AzSecurityRecommendation -RecommendationId $recommendations[0].Id `
    -TestMode

# Auto-implement with parameters
$params = @{
    "location" = "eastus"
    "sku" = "Standard_LRS"
}

Invoke-AzSecurityRecommendation -RecommendationId "enable-storage-encryption" `
    -Parameters $params `
    -AutoApprove

# Implement with approval workflow
Invoke-AzSecurityRecommendation -RecommendationId "enable-mfa" `
    -ApprovalEmail "security-approvers@company.com"
```

## Advanced Scenarios

### Multi-Subscription Security Management

```powershell
# Get all subscriptions
$subscriptions = Get-AzSubscription | Where-Object State -eq "Enabled"

# Enable Security Center across all subscriptions
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id
    
    Enable-AzSecurityCenterAdvanced -SubscriptionId $sub.Id `
        -Tier "Standard" `
        -EnableAutoProvisioning `
        -SecurityContactEmails @("security@company.com")
    
    # Enable all Defender plans
    $plans = @("VirtualMachines", "SqlServers", "AppServices", "StorageAccounts", "KeyVaults")
    foreach ($plan in $plans) {
        Set-AzDefenderPlan -PlanName $plan -Enable
    }
}

# Generate consolidated report
$allScores = @()
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id
    $score = Get-AzSecurityScore
    $allScores += [PSCustomObject]@{
        Subscription = $sub.Name
        Score = $score.Percentage
        Controls = $score.Controls.Count
    }
}

$allScores | Sort-Object Score | Format-Table
```

### Automated Security Remediation

```powershell
# Create remediation runbook
$remediationScript = {
    param($Recommendations)
    
    $results = @()
    foreach ($rec in $Recommendations) {
        if ($rec.Category -eq "QuickWins" -and $rec.Effort -eq "Low") {
            try {
                $result = Invoke-AzSecurityRecommendation -RecommendationId $rec.Id `
                    -AutoApprove
                $results += $result
            }
            catch {
                Write-Warning "Failed to implement $($rec.Name): $_"
            }
        }
    }
    return $results
}

# Get and implement quick wins
$quickWins = Get-AzSecurityRecommendations -Category "QuickWins"
$remediationResults = & $remediationScript -Recommendations $quickWins

# Schedule regular remediation
$actionParams = @{
    Name = "SecurityRemediation"
    ResourceGroupName = "Automation-RG"
    RunbookName = "Invoke-SecurityQuickWins"
    ScheduleName = "WeeklySecurityRemediation"
    StartTime = (Get-Date).AddHours(1)
    Frequency = "Week"
    Interval = 1
}
```

### Compliance Reporting Dashboard

```powershell
# Generate comprehensive compliance data
$frameworks = @("CIS", "NIST", "ISO27001")
$complianceData = @()

foreach ($framework in $frameworks) {
    $compliance = Test-AzSecurityCompliance -PolicySetName "$framework-SecurityBaseline"
    $complianceData += [PSCustomObject]@{
        Framework = $framework
        Compliance = $compliance.OverallCompliance
        Percentage = $compliance.CompliancePercentage
        NonCompliantCount = $compliance.NonCompliantResources.Count
        LastChecked = Get-Date
    }
}

# Export for Power BI
$complianceData | Export-Csv ".\ComplianceData.csv" -NoTypeInformation

# Create HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Security Compliance Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .compliant { color: green; }
        .non-compliant { color: red; }
        .partially-compliant { color: orange; }
    </style>
</head>
<body>
    <h1>Security Compliance Dashboard</h1>
    <table>
        <tr>
            <th>Framework</th>
            <th>Status</th>
            <th>Compliance %</th>
            <th>Non-Compliant Resources</th>
            <th>Last Checked</th>
        </tr>
"@

foreach ($item in $complianceData) {
    $statusClass = switch ($item.Compliance) {
        "Compliant" { "compliant" }
        "NonCompliant" { "non-compliant" }
        default { "partially-compliant" }
    }
    
    $html += @"
        <tr>
            <td>$($item.Framework)</td>
            <td class="$statusClass">$($item.Compliance)</td>
            <td>$($item.Percentage)%</td>
            <td>$($item.NonCompliantCount)</td>
            <td>$($item.LastChecked)</td>
        </tr>
"@
}

$html += @"
    </table>
</body>
</html>
"@

$html | Out-File ".\ComplianceDashboard.html"
```

## Best Practices

1. **Security Center Configuration**
   - Enable Standard tier for all resource types
   - Configure auto-provisioning for monitoring agents
   - Set up security contacts for all subscriptions

2. **Defender Plans**
   - Enable plans based on your resource types
   - Use P2 plans for advanced features
   - Configure extensions for additional protection

3. **Policy Management**
   - Start with built-in compliance frameworks
   - Test policies in audit mode first
   - Use management groups for enterprise-wide policies

4. **Vulnerability Management**
   - Schedule regular assessments (weekly/monthly)
   - Prioritize remediation based on severity and exposure
   - Maintain vulnerability trending reports

5. **Security Score**
   - Set realistic targets with appropriate timelines
   - Focus on quick wins first
   - Track progress monthly

6. **Recommendations**
   - Review and prioritize weekly
   - Automate low-risk quick wins
   - Document exceptions with business justification

## Troubleshooting

### Common Issues

1. **Security Center Not Enabled**
   - Verify subscription permissions (Owner/Contributor)
   - Check if Security Center is available in your region
   - Ensure no policy preventing enablement

2. **Defender Plans Not Applying**
   - Confirm resource types exist in subscription
   - Check for conflicting policies
   - Verify billing account status

3. **Policy Compliance Showing 0%**
   - Allow time for initial evaluation (up to 24 hours)
   - Check policy assignment scope
   - Verify resources match policy conditions

4. **Vulnerability Scan Failures**
   - Ensure agents are installed and running
   - Check network connectivity
   - Verify scanner permissions

## Support

For issues, feature requests, or contributions:
- GitHub: [azure-enterprise-toolkit](https://github.com/wesellis/azure-enterprise-toolkit)
- Email: support@enterprise-azure.com

## License

This module is part of the Azure Enterprise Toolkit and is licensed under the MIT License.