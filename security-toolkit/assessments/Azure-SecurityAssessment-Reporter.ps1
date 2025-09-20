#Requires -Version 7.0
#Requires -Modules Az.KeyVault

<#
.SYNOPSIS
    SecurityAssessment Reporter
.DESCRIPTION
    NOTES
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Security Assessment Reporter
# Professional Azure automation script for
# Version: 2.0 | Enhanced for enterprise security governance

[CmdletBinding()]

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

#region Functions

# Import common functions
# Module import removed - use #Requires instead

# Professional banner
Show-Banner -ScriptName "Azure Security Assessment Reporter" -Version "2.0" -Description "security posture analysis and compliance reporting"

try {
    # Test Azure connection and security modules
    Write-ProgressStep -StepNumber 1 -TotalSteps 10 -StepName "Security Module Validation" -Status "Validating Azure Security Center connectivity"
    
    $requiredModules = @('Az.Accounts', 'Az.Resources', 'Az.Security', 'Az.Monitor', 'Az.KeyVault', 'Az.Network')
    if (-not (Test-AzureConnection -RequiredModules $requiredModules)) {
        throw "Azure connection or required modules validation failed"
    }

    # Initialize assessment results
    $assessmentResults = @{
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

    # Get subscription context
    Write-ProgressStep -StepNumber 2 -TotalSteps 10 -StepName "Scope Definition" -Status "Defining assessment scope"
    
    if ($SubscriptionId -and $SubscriptionId -ne (Get-AzContext).Subscription.Id) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    
    $subscription = Get-AzSubscription -SubscriptionId $assessmentResults.AssessmentMetadata.SubscriptionId
    $assessmentResults.AssessmentMetadata.SubscriptionName = $subscription.Name
    
    Write-Log "[OK] Assessment scope: $($subscription.Name)" -Level SUCCESS

    # Security Center Assessment
    Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Security Center Analysis" -Status "Analyzing Security Center recommendations"
    
    $securityAssessments = Invoke-AzureOperation -Operation {
        if ($ResourceGroupName) {
            Get-AzSecurityAssessment -ErrorAction Stop | Where-Object { $_.Id -like "*$ResourceGroupName*" }
        } else {
            Get-AzSecurityAssessment -ErrorAction Stop
        }
    } -OperationName "Get Security Assessments" -MaxRetries 2

    foreach ($assessment in $securityAssessments) {
        $finding = @{
            Type = "SecurityCenter"
            Resource = $assessment.Id.Split('/')[-3]
            Assessment = $assessment.DisplayName
            Status = $assessment.Status.Code
            Severity = $assessment.Status.Severity
            Description = $assessment.Status.Description
            Category = $assessment.Metadata.Category
        }
        $assessmentResults.SecurityFindings += $finding
    }
    
    Write-Log "[OK] Analyzed $($securityAssessments.Count) Security Center assessments" -Level SUCCESS

    # Network Security Analysis
    Write-ProgressStep -StepNumber 4 -TotalSteps 10 -StepName "Network Security Analysis" -Status "Analyzing network security configurations"
    
    $networkFindings = Invoke-AzureOperation -Operation {
        $nsgs = if ($ResourceGroupName) {
            Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzNetworkSecurityGroup -ErrorAction Stop
        }
        
        $findings = @()
        foreach ($nsg in $nsgs) {
            # Check for overly permissive rules
            $riskyRules = $nsg.SecurityRules | Where-Object {
                $_.Access -eq "Allow" -and 
                $_.SourceAddressPrefix -eq "*" -and 
                $_.DestinationPortRange -in @("22", "3389", "80", "443", "*")
            }
            
            foreach ($rule in $riskyRules) {
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
    
    $assessmentResults.SecurityFindings += $networkFindings
    Write-Log "[OK] Analyzed network security configurations" -Level SUCCESS

    # Key Vault Security Analysis
    Write-ProgressStep -StepNumber 5 -TotalSteps 10 -StepName "Key Vault Security" -Status "Analyzing Key Vault configurations"
    
    $keyVaultFindings = Invoke-AzureOperation -Operation {
        $keyVaults = if ($ResourceGroupName) {
            Get-AzKeyVault -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzKeyVault -ErrorAction Stop
        }
        
        $findings = @()
        foreach ($vault in $keyVaults) {
            $vaultDetails = Get-AzKeyVault -VaultName $vault.VaultName
            
            # Check for public access
            if ($vaultDetails.NetworkAcls.DefaultAction -eq "Allow") {
                $findings += @{
                    Type = "KeyVault"
                    Resource = $vault.VaultName
                    Issue = "Public Network Access Enabled"
                    Severity = "Medium"
                    Details = "Key Vault allows access from all networks"
                    Recommendation = "Enable network restrictions or private endpoints"
                }
            }
            
            # Check for soft delete
            if (-not $vaultDetails.EnableSoftDelete) {
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
    
    $assessmentResults.SecurityFindings += $keyVaultFindings
    Write-Log "[OK] Analyzed Key Vault security configurations" -Level SUCCESS

    # Resource Compliance Analysis
    Write-ProgressStep -StepNumber 6 -TotalSteps 10 -StepName "Compliance Analysis" -Status "Analyzing resource compliance"
    
    $complianceResults = Invoke-AzureOperation -Operation {
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
            # Check tagging compliance
            if ($resource.Tags -and $resource.Tags.Count -ge 3) {
                $compliance.TaggedResources++
            }
            
            # Check naming convention (basic check)
            if ($resource.Name -match '^[a-z]+(-[a-z0-9]+)*$') {
                $compliance.CompliantNaming++
            }
            
            # Check for encryption (basic indicators)
            if ($resource.Kind -like "*encrypted*" -or $resource.Properties -like "*encryption*") {
                $compliance.EncryptedResources++
            }
        }
        
        return $compliance
    } -OperationName "Analyze Resource Compliance"
    
    $assessmentResults.ComplianceScore = $complianceResults
    Write-Log "[OK] Analyzed resource compliance" -Level SUCCESS

    # Policy Compliance Analysis
    Write-ProgressStep -StepNumber 7 -TotalSteps 10 -StepName "Policy Analysis" -Status "Analyzing Azure Policy compliance"
    
    $policyStates = Invoke-AzureOperation -Operation {
        # Get policy states (requires Az.PolicyInsights module)
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
    
    $policyFindings = $policyStates | ForEach-Object {
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
    
    $assessmentResults.SecurityFindings += $policyFindings
    Write-Log "[OK] Analyzed Azure Policy compliance" -Level SUCCESS

    # Generate Recommendations
    Write-ProgressStep -StepNumber 8 -TotalSteps 10 -StepName "Recommendations" -Status "Generating security recommendations"
    
    if ($IncludeRecommendations) {
        $recommendations = @()
        
        # High-priority recommendations based on findings
        $highSeverityFindings = $assessmentResults.SecurityFindings | Where-Object { $_.Severity -eq "High" }
        if ($highSeverityFindings.Count -gt 0) {
            $recommendations += @{
                Priority = "High"
                Category = "Critical Security Issues"
                Description = "Address $($highSeverityFindings.Count) critical security findings immediately"
                ActionItems = $highSeverityFindings | ForEach-Object { $_.Issue }
            }
        }
        
        # Compliance recommendations
        $complianceRate = [math]::Round(($complianceResults.TaggedResources / $complianceResults.TotalResources) * 100, 2)
        if ($complianceRate -lt 80) {
            $recommendations += @{
                Priority = "Medium"
                Category = "Governance"
                Description = "Improve resource tagging compliance (currently $complianceRate%)"
                ActionItems = @("Implement tagging policies", "Audit untagged resources", "Establish tagging standards")
            }
        }
        
        $assessmentResults.Recommendations = $recommendations
    }

    # Calculate Security Score
    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName "Security Scoring" -Status "Calculating overall security score"
    
    $securityScore = @{
        OverallScore = 0
        MaxPossibleScore = 100
        CategoryScores = @{}
    }
    
    # Calculate scores based on findings
    $criticalIssues = ($assessmentResults.SecurityFindings | Where-Object { $_.Severity -eq "High" }).Count
    $mediumIssues = ($assessmentResults.SecurityFindings | Where-Object { $_.Severity -eq "Medium" }).Count
    $lowIssues = ($assessmentResults.SecurityFindings | Where-Object { $_.Severity -eq "Low" }).Count
    
    # Simple scoring algorithm
    $scoreDeduction = ($criticalIssues * 20) + ($mediumIssues * 10) + ($lowIssues * 5)
    $securityScore.OverallScore = [math]::Max(0, 100 - $scoreDeduction)
    
    $securityScore.CategoryScores = @{
        NetworkSecurity = [math]::Max(0, 100 - (($networkFindings | Where-Object { $_.Severity -eq "High" }).Count * 25))
        IdentityAndAccess = [math]::Max(0, 100 - (($keyVaultFindings | Where-Object { $_.Severity -eq "High" }).Count * 25))
        DataProtection = $complianceResults.EncryptedResources / $complianceResults.TotalResources * 100
        Governance = $complianceRate
    }
    
    $assessmentResults.Summary = @{
        SecurityScore = $securityScore
        TotalFindings = $assessmentResults.SecurityFindings.Count
        CriticalFindings = $criticalIssues
        MediumFindings = $mediumIssues
        LowFindings = $lowIssues
        ComplianceRate = $complianceRate
    }

    # Export Results
    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName "Export Results" -Status "Exporting assessment results"
    
    # JSON Export
    $assessmentResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Log "[OK] Assessment results exported to: $OutputPath" -Level SUCCESS
    
    # CSV Export if requested
    if ($ExportToCSV) {
        $csvPath = $OutputPath.Replace('.json', '.csv')
        $assessmentResults.SecurityFindings | Export-Csv -Path $csvPath -NoTypeInformation -Force
        Write-Log "[OK] Findings exported to CSV: $csvPath" -Level SUCCESS
    }
    
    # Log Analytics Export if requested
    if ($SendToLogAnalytics -and $LogAnalyticsWorkspaceId) {
        try {
            # Send to Log Analytics (requires custom implementation)
            Write-Log "Log Analytics integration would be implemented here" -Level INFO
        } catch {
            Write-Log "Failed to send to Log Analytics: $($_.Exception.Message)" -Level WARN
        }
    }

    # Display Summary
    Write-Host ""
    Write-Host ""
    Write-Host "                              SECURITY ASSESSMENT COMPLETED"  
    Write-Host ""
    Write-Host ""
    Write-Host "Security Score: $($securityScore.OverallScore)/100" -ForegroundColor $(if ($securityScore.OverallScore -ge 80) { "Green" } elseif ($securityScore.OverallScore -ge 60) { "Yellow" } else { "Red" })
    Write-Host ""
    Write-Host "Assessment Summary:"
    Write-Host "    Total Resources: $($complianceResults.TotalResources)"
    Write-Host "    Security Findings: $($assessmentResults.Summary.TotalFindings)"
    Write-Host "    Critical Issues: $($assessmentResults.Summary.CriticalFindings)"
    Write-Host "    Medium Issues: $($assessmentResults.Summary.MediumFindings)"
    Write-Host "    Low Issues: $($assessmentResults.Summary.LowFindings)"
    Write-Host "    Compliance Rate: $($assessmentResults.Summary.ComplianceRate)%"
    Write-Host ""
    Write-Host "�� Output Files:"
    Write-Host "    JSON Report: $OutputPath"
    if ($ExportToCSV) {
        Write-Host "    CSV Export: $csvPath"
    }
    Write-Host ""
    
    if ($assessmentResults.Summary.CriticalFindings -gt 0) {
        Write-Host "[WARN]  ATTENTION: $($assessmentResults.Summary.CriticalFindings) critical security issues require immediate attention!"
        Write-Host ""
    }

    Write-Log "Security assessment completed successfully!" -Level SUCCESS

} catch {
    Write-Log "Security assessment failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Host ""
    Write-Host "Troubleshooting Tips:"
    Write-Host "    Verify Security Center is enabled on the subscription"
    Write-Host "    Check permissions for Security Reader role"
    Write-Host "    Ensure Az.Security module is installed and updated"
    Write-Host "    Validate subscription and resource group access"
    Write-Host ""
    
    throw
}

Write-Progress -Activity "Security Assessment" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO

#endregion

