#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
    SecurityAssessment Reporter
.DESCRIPTION
    NOTES
    Author: Wes Ellis (wes@wesellis.com)

[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$SubscriptionId,

    [Parameter()]
    [ValidateSet("Quick", "", "Compliance", "Custom")]
    [string]$AssessmentType = "Quick",

    [Parameter()]
    [string]$OutputPath = ".\SecurityAssessment-$(Get-Date -Format 'yyyyMMdd-HHmmss').json",

    [Parameter()]
    [string]$ReportFormat = "JSON",

    [Parameter()]
    [switch]$IncludeRecommendations,

    [Parameter()]
    [switch]$ExportToCSV,

    [Parameter()]
    [switch]$SendToLogAnalytics,

    [Parameter()]
    [string]$LogAnalyticsWorkspaceId
)


Show-Banner -ScriptName "Azure Security Assessment Reporter" -Version "2.0" -Description "security posture analysis and compliance reporting"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 10 -StepName "Security Module Validation" -Status "Validating Azure Security Center connectivity"

    $RequiredModules = @('Az.Accounts', 'Az.Resources', 'Az.Security', 'Az.Monitor', 'Az.KeyVault', 'Az.Network')
    if (-not (Test-AzureConnection -RequiredModules $RequiredModules)) {
        throw "Azure connection or required modules validation failed"
    }

    $AssessmentResults = @{
        AssessmentMetadata = @{
            AssessmentType = $AssessmentType
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
            SubscriptionId = if ($SubscriptionId) { $SubscriptionId } else { (Get-AzContext).Subscription.Id }
            ResourceGroupScope = $ResourceGroupName
            GeneratedBy = $env:USERNAME
            ToolVersion = "2.0"
        }
        SecurityFindings = @()
        ComplianceScore = @{}
        Recommendations = @()
        Summary = @{}
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 10 -StepName "Scope Definition" -Status "Defining assessment scope"

    if ($SubscriptionId -and $SubscriptionId -ne (Get-AzContext).Subscription.Id) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }

    $subscription = Get-AzSubscription -SubscriptionId $AssessmentResults.AssessmentMetadata.SubscriptionId
    $AssessmentResults.AssessmentMetadata.SubscriptionName = $subscription.Name

    Write-Log "[OK] Assessment scope: $($subscription.Name)" -Level SUCCESS

    Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Security Center Analysis" -Status "Analyzing Security Center recommendations"

    $SecurityAssessments = Invoke-AzureOperation -Operation {
        if ($ResourceGroupName) {
            Get-AzSecurityAssessment -ErrorAction Stop | Where-Object { $_.Id -like "*$ResourceGroupName*" }
        } else {
            Get-AzSecurityAssessment -ErrorAction Stop
        }
    } -OperationName "Get Security Assessments" -MaxRetries 2

    foreach ($assessment in $SecurityAssessments) {
        $finding = @{
            Type = "SecurityCenter"
            Resource = $assessment.Id.Split('/')[-3]
            Assessment = $assessment.DisplayName
            Status = $assessment.Status.Code
            Severity = $assessment.Status.Severity
            Description = $assessment.Status.Description
            Category = $assessment.Metadata.Category
        }
        $AssessmentResults.SecurityFindings += $finding
    }

    Write-Log "[OK] Analyzed $($SecurityAssessments.Count) Security Center assessments" -Level SUCCESS

    Write-ProgressStep -StepNumber 4 -TotalSteps 10 -StepName "Network Security Analysis" -Status "Analyzing network security configurations"

    $NetworkFindings = Invoke-AzureOperation -Operation {
        $nsgs = if ($ResourceGroupName) {
            Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzNetworkSecurityGroup -ErrorAction Stop
        }

        $findings = @()
        foreach ($nsg in $nsgs) {
            $RiskyRules = $nsg.SecurityRules | Where-Object {
                $_.Access -eq "Allow" -and
                $_.SourceAddressPrefix -eq "*" -and
                $_.DestinationPortRange -in @("22", "3389", "80", "443", "*")
            }

            foreach ($rule in $RiskyRules) {
                $findings += @{
                    Type = "NetworkSecurity"
                    Resource = $nsg.Name
                    Issue = "Overly Permissive NSG Rule"
                    Severity = "High"
                    Details = "Rule '$($rule.Name)' allows access from any source to port $($rule.DestinationPortRange)"
                    Recommendation = "Restrict source IP addresses or use Application Security Groups"
                }
            }
        }
        return $findings
    } -OperationName "Analyze Network Security"

    $AssessmentResults.SecurityFindings += $NetworkFindings
    Write-Log "[OK] Analyzed network security configurations" -Level SUCCESS

    Write-ProgressStep -StepNumber 5 -TotalSteps 10 -StepName "Key Vault Security" -Status "Analyzing Key Vault configurations"

    $KeyVaultFindings = Invoke-AzureOperation -Operation {
        $KeyVaults = if ($ResourceGroupName) {
            Get-AzKeyVault -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzKeyVault -ErrorAction Stop
        }

        $findings = @()
        foreach ($vault in $KeyVaults) {
            $VaultDetails = Get-AzKeyVault -VaultName $vault.VaultName

            if ($VaultDetails.NetworkAcls.DefaultAction -eq "Allow") {
                $findings += @{
                    Type = "KeyVault"
                    Resource = $vault.VaultName
                    Issue = "Public Network Access Enabled"
                    Severity = "Medium"
                    Details = "Key Vault allows access from all networks"
                    Recommendation = "Enable network restrictions or private endpoints"
                }
            }

            if (-not $VaultDetails.EnableSoftDelete) {
                $findings += @{
                    Type = "KeyVault"
                    Resource = $vault.VaultName
                    Issue = "Soft Delete Disabled"
                    Severity = "High"
                    Details = "Key Vault does not have soft delete enabled"
                    Recommendation = "Enable soft delete for data protection"
                }
            }
        }
        return $findings
    } -OperationName "Analyze Key Vault Security"

    $AssessmentResults.SecurityFindings += $KeyVaultFindings
    Write-Log "[OK] Analyzed Key Vault security configurations" -Level SUCCESS

    Write-ProgressStep -StepNumber 6 -TotalSteps 10 -StepName "Compliance Analysis" -Status "Analyzing resource compliance"

    $ComplianceResults = Invoke-AzureOperation -Operation {
        $resources = if ($ResourceGroupName) {
            Get-AzResource -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzResource -ErrorAction Stop
        }

        $compliance = @{
            TotalResources = $resources.Count
            TaggedResources = 0
            EncryptedResources = 0
            MonitoredResources = 0
            CompliantNaming = 0
        }

        foreach ($resource in $resources) {
            if ($resource.Tags -and $resource.Tags.Count -ge 3) {
                $compliance.TaggedResources++
            }

            if ($resource.Name -match '^[a-z]+(-[a-z0-9]+)*$') {
                $compliance.CompliantNaming++
            }

            if ($resource.Kind -like "*encrypted*" -or $resource.Properties -like "*encryption*") {
                $compliance.EncryptedResources++
            }
        }

        return $compliance
    } -OperationName "Analyze Resource Compliance"

    $AssessmentResults.ComplianceScore = $ComplianceResults
    Write-Log "[OK] Analyzed resource compliance" -Level SUCCESS

    Write-ProgressStep -StepNumber 7 -TotalSteps 10 -StepName "Policy Analysis" -Status "Analyzing Azure Policy compliance"

    $PolicyStates = Invoke-AzureOperation -Operation {
        try {
            if (Get-Module Az.PolicyInsights -ListAvailable -ErrorAction Stop) {
                Import-Module Az.PolicyInsights
                $filter = if ($ResourceGroupName) { "ResourceGroup eq '$ResourceGroupName'" } else { $null }
                Get-AzPolicyState -Filter $filter | Select-Object -First 100
            } else {
                Write-Log "Az.PolicyInsights module not available, skipping policy analysis" -Level WARN
                return @()
            }
        } catch {
            Write-Log "Policy analysis failed: $($_.Exception.Message)" -Level WARN
            return @()
        }
    } -OperationName "Analyze Policy Compliance"

    $PolicyFindings = $PolicyStates | ForEach-Object {
        if ($_.ComplianceState -eq "NonCompliant") {
            @{
                Type = "PolicyCompliance"
                Resource = $_.ResourceId.Split('/')[-1]
                Issue = "Policy Non-Compliance"
                Severity = "Medium"
                Details = "Resource violates policy: $($_.PolicyDefinitionName)"
                PolicyName = $_.PolicyDefinitionName
            }
        }
    }

    $AssessmentResults.SecurityFindings += $PolicyFindings
    Write-Log "[OK] Analyzed Azure Policy compliance" -Level SUCCESS

    Write-ProgressStep -StepNumber 8 -TotalSteps 10 -StepName "Recommendations" -Status "Generating security recommendations"

    if ($IncludeRecommendations) {
        $recommendations = @()

        $HighSeverityFindings = $AssessmentResults.SecurityFindings | Where-Object { $_.Severity -eq "High" }
        if ($HighSeverityFindings.Count -gt 0) {
            $recommendations += @{
                Priority = "High"
                Category = "Critical Security Issues"
                Description = "Address $($HighSeverityFindings.Count) critical security findings immediately"
                ActionItems = $HighSeverityFindings | ForEach-Object { $_.Issue }
            }
        }

        $ComplianceRate = [math]::Round(($ComplianceResults.TaggedResources / $ComplianceResults.TotalResources) * 100, 2)
        if ($ComplianceRate -lt 80) {
            $recommendations += @{
                Priority = "Medium"
                Category = "Governance"
                Description = "Improve resource tagging compliance (currently $ComplianceRate%)"
                ActionItems = @("Implement tagging policies", "Audit untagged resources", "Establish tagging standards")
            }
        }

        $AssessmentResults.Recommendations = $recommendations
    }

    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName "Security Scoring" -Status "Calculating overall security score"

    $SecurityScore = @{
        OverallScore = 0
        MaxPossibleScore = 100
        CategoryScores = @{}
    }

    $CriticalIssues = ($AssessmentResults.SecurityFindings | Where-Object { $_.Severity -eq "High" }).Count
    $MediumIssues = ($AssessmentResults.SecurityFindings | Where-Object { $_.Severity -eq "Medium" }).Count
    $LowIssues = ($AssessmentResults.SecurityFindings | Where-Object { $_.Severity -eq "Low" }).Count

    $ScoreDeduction = ($CriticalIssues * 20) + ($MediumIssues * 10) + ($LowIssues * 5)
    $SecurityScore.OverallScore = [math]::Max(0, 100 - $ScoreDeduction)

    $SecurityScore.CategoryScores = @{
        NetworkSecurity = [math]::Max(0, 100 - (($NetworkFindings | Where-Object { $_.Severity -eq "High" }).Count * 25))
        IdentityAndAccess = [math]::Max(0, 100 - (($KeyVaultFindings | Where-Object { $_.Severity -eq "High" }).Count * 25))
        DataProtection = $ComplianceResults.EncryptedResources / $ComplianceResults.TotalResources * 100
        Governance = $ComplianceRate
    }

    $AssessmentResults.Summary = @{
        SecurityScore = $SecurityScore
        TotalFindings = $AssessmentResults.SecurityFindings.Count
        CriticalFindings = $CriticalIssues
        MediumFindings = $MediumIssues
        LowFindings = $LowIssues
        ComplianceRate = $ComplianceRate
    }

    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName "Export Results" -Status "Exporting assessment results"

    $AssessmentResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Log "[OK] Assessment results exported to: $OutputPath" -Level SUCCESS

    if ($ExportToCSV) {
        $CsvPath = $OutputPath.Replace('.json', '.csv')
        $AssessmentResults.SecurityFindings | Export-Csv -Path $CsvPath -NoTypeInformation -Force
        Write-Log "[OK] Findings exported to CSV: $CsvPath" -Level SUCCESS
    }

    if ($SendToLogAnalytics -and $LogAnalyticsWorkspaceId) {
        try {
            Write-Log "Log Analytics integration would be implemented here" -Level INFO
        } catch {
            Write-Log "Failed to send to Log Analytics: $($_.Exception.Message)" -Level WARN
        }
    }

    Write-Output ""
    Write-Output ""
    Write-Output "                              SECURITY ASSESSMENT COMPLETED"
    Write-Output ""
    Write-Output ""
    Write-Output "Security Score: $($SecurityScore.OverallScore)/100" -ForegroundColor $(if ($SecurityScore.OverallScore -ge 80) { "Green" } elseif ($SecurityScore.OverallScore -ge 60) { "Yellow" } else { "Red" })
    Write-Output ""
    Write-Output "Assessment Summary:"
    Write-Output "    Total Resources: $($ComplianceResults.TotalResources)"
    Write-Output "    Security Findings: $($AssessmentResults.Summary.TotalFindings)"
    Write-Output "    Critical Issues: $($AssessmentResults.Summary.CriticalFindings)"
    Write-Output "    Medium Issues: $($AssessmentResults.Summary.MediumFindings)"
    Write-Output "    Low Issues: $($AssessmentResults.Summary.LowFindings)"
    Write-Output "    Compliance Rate: $($AssessmentResults.Summary.ComplianceRate)%"
    Write-Output ""
    Write-Output "�� Output Files:"
    Write-Output "    JSON Report: $OutputPath"
    if ($ExportToCSV) {
        Write-Output "    CSV Export: $CsvPath"
    }
    Write-Output ""

    if ($AssessmentResults.Summary.CriticalFindings -gt 0) {
        Write-Output "[WARN]  ATTENTION: $($AssessmentResults.Summary.CriticalFindings) critical security issues require immediate attention!"
        Write-Output ""
    }

    Write-Log "Security assessment completed successfully!" -Level SUCCESS

} catch {
    Write-Log "Security assessment failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception

    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify Security Center is enabled on the subscription"
    Write-Output "    Check permissions for Security Reader role"
    Write-Output "    Ensure Az.Security module is installed and updated"
    Write-Output "    Validate subscription and resource group access"
    Write-Output ""

    throw
}

Write-Progress -Activity "Security Assessment" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



