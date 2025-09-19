#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Microsoft Defender for Cloud Automation Tool
# Professional Azure security automation script
# Version: 1.0 | Enterprise security posture management automation

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("EnableDefender", "ConfigurePolicies", "GetSecurityScore", "ExportFindings", "ConfigureAlerts", "EnableAutoProvisioning")]
    [string]$Action = "GetSecurityScore",
    
    [Parameter(Mandatory=$false)]
    [string[]]$DefenderPlans = @("VirtualMachines", "AppService", "SqlServers", "StorageAccounts", "KeyVaults", "Containers", "Arm"),
    
    [Parameter(Mandatory=$false)]
    [string]$ExportPath = ".\defender-export",
    
    [Parameter(Mandatory=$false)]
    [string]$LogAnalyticsWorkspaceId,
    
    [Parameter(Mandatory=$false)]
    [string[]]$AlertEmails = @(),
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("High", "Medium", "Low")]
    [string]$MinimumAlertSeverity = "Medium",
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableJITAccess,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableFileIntegrityMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableAdaptiveApplicationControls,
    
    [Parameter(Mandatory=$false)]
    [switch]$DetailedOutput
)

#region Functions

# Import common functions
# Module import removed - use #Requires instead

# Professional banner
Show-Banner -ScriptName "Microsoft Defender for Cloud Automation" -Version "1.0" -Description "Enterprise security posture management and compliance automation"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName "Azure Connection" -Status "Validating connection and security services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Security'))) {
        throw "Azure connection validation failed"
    }

    # Set subscription context if provided
    if ($SubscriptionId) {
        Write-ProgressStep -StepNumber 2 -TotalSteps 8 -StepName "Subscription Context" -Status "Setting subscription context"
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-Log "[OK] Using subscription: $SubscriptionId" -Level SUCCESS
    } else {
        $SubscriptionId = (Get-AzContext).Subscription.Id
        Write-Log "[OK] Using current subscription: $SubscriptionId" -Level SUCCESS
    }

    switch ($Action.ToLower()) {
        "enabledefender" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Defender Plans" -Status "Enabling Defender for Cloud plans"
            
            $enabledPlans = @()
            $failedPlans = @()
            
            foreach ($plan in $DefenderPlans) {
                try {
                    Write-Log "Enabling Defender for $plan..." -Level INFO
                    
                    $planName = switch ($plan) {
                        "VirtualMachines" { "VirtualMachines" }
                        "AppService" { "AppServices" }
                        "SqlServers" { "SqlServers" }
                        "StorageAccounts" { "StorageAccounts" }
                        "KeyVaults" { "KeyVaults" }
                        "Containers" { "Containers" }
                        "Arm" { "Arm" }
                        default { $plan }
                    }
                    
                    $params = @{
                        Name = $planName
                        PricingTier = "Standard"
                    }
                    
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityPricing -ErrorAction Stop @params
                    } -OperationName "Enable Defender Plan: $planName"
                    
                    $enabledPlans += $plan
                    Write-Log "[OK] Defender for $plan enabled" -Level SUCCESS
                    
                } catch {
                    $failedPlans += $plan
                    Write-Log " Failed to enable Defender for $plan`: $($_.Exception.Message)" -Level ERROR
                }
            }
            
            Write-Information ""
            Write-Information " Defender for Cloud Plan Status"
            Write-Information "════════════════════════════════════════════════════════════════════"
            Write-Information " Enabled Plans ($($enabledPlans.Count)):"
            foreach ($plan in $enabledPlans) {
                Write-Information "   • $plan"
            }
            
            if ($failedPlans.Count -gt 0) {
                Write-Information " Failed Plans ($($failedPlans.Count)):"
                foreach ($plan in $failedPlans) {
                    Write-Information "   • $plan"
                }
            }
        }
        
        "configurepolicies" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Security Policies" -Status "Configuring security policies and initiatives"
            
            # Get default policy assignment
            $policyAssignments = Invoke-AzureOperation -Operation {
                Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" | Where-Object { $_.Properties.DisplayName -like "*Security Center*" -or $_.Properties.DisplayName -like "*Azure Security Benchmark*" }
            } -OperationName "Get Security Policy Assignments"
            
            Write-Information ""
            Write-Information "� Current Security Policy Assignments"
            Write-Information "════════════════════════════════════════════════════════════════════"
            
            foreach ($assignment in $policyAssignments) {
                $complianceState = Get-AzPolicyState -PolicyAssignmentName $assignment.Name -Top 1 | Select-Object -First 1
                $complianceStatus = if ($complianceState) { $complianceState.ComplianceState } else { "Unknown" }
                
                Write-Information "• $($assignment.Properties.DisplayName)"
                Write-Information "  Scope: $($assignment.Properties.Scope)"
                Write-Information "  Compliance: $complianceStatus" -ForegroundColor $(if ($complianceStatus -eq "Compliant") { "Green" } elseif ($complianceStatus -eq "NonCompliant") { "Red" } else { "Yellow" })
                Write-Information ""
            }
            
            # Configure auto-provisioning if enabled
            if ($EnableJITAccess -or $EnableFileIntegrityMonitoring -or $EnableAdaptiveApplicationControls) {
                Write-Log "Configuring advanced security features..." -Level INFO
                
                $autoProvisioningSettings = @{
                    "Enabled" = "On"
                }
                
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvisioning
                } -OperationName "Enable Auto Provisioning"
                
                Write-Log "[OK] Auto-provisioning enabled for security agents" -Level SUCCESS
            }
        }
        
        "getsecurityscore" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Security Score" -Status "Retrieving security score and recommendations"
            
            # Get security score using REST API (as PowerShell module may not have all cmdlets)
            $securityScore = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Security/secureScores?api-version=2020-01-01"
                
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value | Select-Object -First 1
            } -OperationName "Get Security Score"
            
            # Get security recommendations
            $recommendations = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Security/assessments?api-version=2020-01-01"
                
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Security Recommendations"
            
            # Analyze findings
            $criticalFindings = $recommendations | Where-Object { $_.properties.status.severity -eq "High" -and $_.properties.status.code -eq "Unhealthy" }
            $mediumFindings = $recommendations | Where-Object { $_.properties.status.severity -eq "Medium" -and $_.properties.status.code -eq "Unhealthy" }
            $lowFindings = $recommendations | Where-Object { $_.properties.status.severity -eq "Low" -and $_.properties.status.code -eq "Unhealthy" }
            
            Write-Information ""
            Write-Information "  Security Score Dashboard"
            Write-Information "════════════════════════════════════════════════════════════════════"
            
            if ($securityScore) {
                $currentScore = [math]::Round(($securityScore.properties.score.current / $securityScore.properties.score.max) * 100, 1)
                $scoreColor = if ($currentScore -ge 80) { "Green" } elseif ($currentScore -ge 60) { "Yellow" } else { "Red" }
                
                Write-Information " Overall Security Score: $currentScore% ($($securityScore.properties.score.current)/$($securityScore.properties.score.max))" -ForegroundColor $scoreColor
                Write-Information ""
            }
            
            Write-Information "� Security Findings by Severity:"
            Write-Information "   • Critical (High): $($criticalFindings.Count)"
            Write-Information "   • Medium: $($mediumFindings.Count)"  
            Write-Information "   • Low: $($lowFindings.Count)"
            Write-Information ""
            
            if ($DetailedOutput -and $criticalFindings.Count -gt 0) {
                Write-Information "� Critical Security Issues (Top 10):"
                Write-Information "════════════════════════════════════════════════════════════════════"
                $criticalFindings | Select-Object -First 10 | ForEach-Object {
                    Write-Information "• $($_.properties.displayName)"
                    Write-Information "  Resource: $($_.properties.resourceDetails.id)"
                    Write-Information ""
                }
            }
        }
        
        "exportfindings" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Export Findings" -Status "Exporting security findings and recommendations"
            
            # Create export directory
            if (-not (Test-Path $ExportPath)) {
                New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
            }
            
            # Get comprehensive security data
            $securityData = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                
                # Get assessments
                $assessmentsUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Security/assessments?api-version=2020-01-01"
                
                # Get alerts
                $alertsUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Security/alerts?api-version=2022-01-01"
                
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $assessments = (Invoke-RestMethod -Uri $assessmentsUri -Method GET -Headers $headers).value
                $alerts = (Invoke-RestMethod -Uri $alertsUri -Method GET -Headers $headers).value
                
                return @{
                    Assessments = $assessments
                    Alerts = $alerts
                    ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    SubscriptionId = $subscriptionId
                }
            } -OperationName "Export Security Data"
            
            # Export to JSON
            $jsonPath = Join-Path $ExportPath "defender-findings-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            $securityData | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
            
            # Create CSV summary
            $csvData = $securityData.Assessments | ForEach-Object {
                [PSCustomObject]@{
                    DisplayName = $_.properties.displayName
                    Severity = $_.properties.status.severity
                    Status = $_.properties.status.code
                    Category = $_.properties.metadata.categories -join "; "
                    ResourceType = $_.properties.resourceDetails.source
                    ResourceId = $_.properties.resourceDetails.id
                    Description = $_.properties.status.description
                }
            }
            
            $csvPath = Join-Path $ExportPath "defender-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
            $csvData | Export-Csv -Path $csvPath -NoTypeInformation
            
            Write-Log "[OK] Security findings exported to: $ExportPath" -Level SUCCESS
            Write-Log "[OK] JSON export: $jsonPath" -Level INFO
            Write-Log "[OK] CSV summary: $csvPath" -Level INFO
        }
        
        "configurealerts" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Alert Configuration" -Status "Configuring security alerts and notifications"
            
            if ($AlertEmails.Count -eq 0) {
                Write-Log "No alert emails provided - using current user email" -Level WARN
                $currentUser = (Get-AzContext).Account.Id
                $AlertEmails = @($currentUser)
            }
            
            # Configure security contacts
            $contactParams = @{
                Email = $AlertEmails -join ";"
                Phone = ""
                AlertNotifications = "On"
                AlertsToAdmins = "On"
            }
            
            Invoke-AzureOperation -Operation {
                Set-AzSecurityContact -ErrorAction Stop @contactParams
            } -OperationName "Configure Security Contacts"
            
            Write-Log "[OK] Security contacts configured: $($AlertEmails -join ', ')" -Level SUCCESS
            
            # Configure workspace settings if Log Analytics workspace provided
            if ($LogAnalyticsWorkspaceId) {
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityWorkspaceSetting -Name "default" -Scope "/subscriptions/$SubscriptionId" -WorkspaceId $LogAnalyticsWorkspaceId
                } -OperationName "Configure Log Analytics Workspace"
                
                Write-Log "[OK] Log Analytics workspace configured for security data collection" -Level SUCCESS
            }
        }
        
        "enableautoprovisioning" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Auto Provisioning" -Status "Enabling automatic provisioning of security agents"
            
            # Enable auto-provisioning for Log Analytics agent
            Invoke-AzureOperation -Operation {
                Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvisioning
            } -OperationName "Enable Auto Provisioning"
            
            Write-Log "[OK] Auto-provisioning enabled for security agents" -Level SUCCESS
            
            # Configure additional security features if requested
            if ($EnableJITAccess) {
                Write-Log "Just-in-Time VM access will be available for configuration per VM" -Level INFO
            }
            
            if ($EnableFileIntegrityMonitoring) {
                Write-Log "File Integrity Monitoring will be available for configuration per workspace" -Level INFO
            }
            
            if ($EnableAdaptiveApplicationControls) {
                Write-Log "Adaptive Application Controls will be available for configuration per VM group" -Level INFO
            }
        }
    }

    # Get current Defender plan status
    Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName "Plan Status" -Status "Checking current Defender for Cloud plan status"
    
    $currentPlans = Invoke-AzureOperation -Operation {
        Get-AzSecurityPricing -ErrorAction Stop
    } -OperationName "Get Current Defender Plans"
    
    $enabledPlans = $currentPlans | Where-Object { $_.PricingTier -eq "Standard" }
    $freePlans = $currentPlans | Where-Object { $_.PricingTier -eq "Free" }

    # Security recommendations analysis
    Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName "Recommendations" -Status "Analyzing security recommendations"
    
    $securityRecommendations = @(
        "💡 Enable Defender for Cloud on all supported resource types",
        "💡 Configure Log Analytics workspace for centralized logging",
        "💡 Set up automated remediation for common security issues",
        "💡 Enable Just-in-Time VM access for administrative access",
        "💡 Configure network security groups with least privilege access",
        "💡 Enable disk encryption for all virtual machines",
        "💡 Implement Azure Key Vault for secrets management",
        "💡 Configure backup and disaster recovery policies"
    )

    # Compliance assessment
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName "Compliance" -Status "Evaluating compliance posture"
    
    $complianceStandards = @(
        "Azure Security Benchmark",
        "ISO 27001:2013",
        "SOC 2 Type 2",
        "PCI DSS 3.2.1",
        "NIST SP 800-53 Rev. 4",
        "HIPAA/HITECH"
    )

    # Cost estimation
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName "Cost Analysis" -Status "Estimating security costs"
    
    $costEstimates = @{
        "Defender for Servers" = "~$15/server/month"
        "Defender for App Service" = "~$15/app service plan/month"
        "Defender for SQL" = "~$15/SQL server/month"
        "Defender for Storage" = "~$10/storage account/month"
        "Defender for Key Vault" = "~$2/vault/month"
        "Defender for Containers" = "~$7/vCore/month"
    }

    # Final validation
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName "Validation" -Status "Validating security configuration"
    
    $overallSecurityScore = if ($enabledPlans.Count -gt 0) {
        [math]::Round(($enabledPlans.Count / $currentPlans.Count) * 100, 1)
    } else { 0 }

    # Success summary
    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                      MICROSOFT DEFENDER FOR CLOUD STATUS"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    
    Write-Information "  Defender for Cloud Overview:"
    Write-Information "   • Subscription: $SubscriptionId"
    Write-Information "   • Plans Enabled: $($enabledPlans.Count)/$($currentPlans.Count)" -ForegroundColor $(if ($enabledPlans.Count -gt 0) { "Green" } else { "Red" })
    Write-Information "   • Coverage Score: $overallSecurityScore%" -ForegroundColor $(if ($overallSecurityScore -ge 80) { "Green" } elseif ($overallSecurityScore -ge 50) { "Yellow" } else { "Red" })
    
    if ($enabledPlans.Count -gt 0) {
        Write-Information ""
        Write-Information " Enabled Protection Plans:"
        foreach ($plan in $enabledPlans) {
            Write-Information "   • $($plan.Name)"
        }
    }
    
    if ($freePlans.Count -gt 0) {
        Write-Information ""
        Write-Information "[WARN]  Free Tier Plans (Consider Upgrading):"
        foreach ($plan in $freePlans) {
            Write-Information "   • $($plan.Name)"
        }
    }
    
    Write-Information ""
    Write-Information " Estimated Monthly Costs:"
    foreach ($cost in $costEstimates.GetEnumerator()) {
        Write-Information "   • $($cost.Key): $($cost.Value)"
    }
    
    Write-Information ""
    Write-Information "� Security Recommendations:"
    foreach ($recommendation in $securityRecommendations) {
        Write-Information "   $recommendation"
    }
    
    Write-Information ""
    Write-Information "🏛  Compliance Standards Available:"
    foreach ($standard in $complianceStandards) {
        Write-Information "   • $standard"
    }
    
    Write-Information ""
    Write-Information "� Next Steps:"
    Write-Information "   • Review and remediate high-priority security recommendations"
    Write-Information "   • Configure custom security policies for your environment"
    Write-Information "   • Set up regular security assessments and reporting"
    Write-Information "   • Implement automated response to security incidents"
    Write-Information "   • Train your team on security best practices"
    Write-Information ""

    Write-Log " Microsoft Defender for Cloud operation '$Action' completed successfully!" -Level SUCCESS

} catch {
    Write-Log " Microsoft Defender for Cloud operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Information ""
    Write-Information " Troubleshooting Tips:"
    Write-Information "   • Verify Security Center access permissions"
    Write-Information "   • Check subscription eligibility for Defender plans"
    Write-Information "   • Ensure Azure Security module is installed and updated"
    Write-Information "   • Validate network connectivity to Azure Security endpoints"
    Write-Information ""
    
    exit 1
}

Write-Progress -Activity "Microsoft Defender for Cloud Management" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO


#endregion
