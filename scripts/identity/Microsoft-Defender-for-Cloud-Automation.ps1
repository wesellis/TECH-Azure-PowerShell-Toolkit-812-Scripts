#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Module Az.Resources
<#`n.SYNOPSIS
    Microsoft Defender for Cloud Automation
.DESCRIPTION
    Microsoft Defender for Cloud Automation operation


    Author: Wes Ellis (wes@wesellis.com)

$ErrorActionPreference = 'Stop'

    Microsoft Defender for Cloud Automationcom)

[CmdletBinding(SupportsShouldProcess)]

    [Parameter()]
    [string]$SubscriptionId,

    [Parameter()]
    [ValidateSet("EnableDefender", "ConfigurePolicies", "GetSecurityScore", "ExportFindings", "ConfigureAlerts", "EnableAutoProvisioning")]
    [string]$Action = "GetSecurityScore",

    [Parameter()]
    [string[]]$DefenderPlans = @("VirtualMachines", "AppService", "SqlServers", "StorageAccounts", "KeyVaults", "Containers", "Arm"),

    [Parameter()]
    [string]$ExportPath = ".\defender-export",

    [Parameter()]
    [string]$LogAnalyticsWorkspaceId,

    [Parameter()]
    [string[]]$AlertEmails = @(),

    [Parameter()]
    [ValidateSet("High", "Medium", "Low")]
    [string]$MinimumAlertSeverity = "Medium",

    [Parameter()]
    [switch]$EnableJITAccess,

    [Parameter()]
    [switch]$EnableFileIntegrityMonitoring,

    [Parameter()]
    [switch]$EnableAdaptiveApplicationControls,

    [Parameter()]
    [switch]$DetailedOutput
)


Show-Banner -ScriptName "Microsoft Defender for Cloud Automation" -Version "1.0" -Description "Enterprise security posture management and compliance automation"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName "Azure Connection" -Status "Validating connection and security services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Security'))) {
        throw "Azure connection validation failed"
    }

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

            $EnabledPlans = @()
            $FailedPlans = @()

            foreach ($plan in $DefenderPlans) {
                try {
                    Write-Log "Enabling Defender for $plan..." -Level INFO

                    $PlanName = switch ($plan) {
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
                        Name = $PlanName
                        PricingTier = "Standard"
                    }

                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityPricing -ErrorAction Stop @params
                    } -OperationName "Enable Defender Plan: $PlanName"

                    $EnabledPlans += $plan
                    Write-Log "[OK] Defender for $plan enabled" -Level SUCCESS

                } catch {
                    $FailedPlans += $plan
                    Write-Log "Failed to enable Defender for $plan`: $($_.Exception.Message)" -Level ERROR
                }
            }

            Write-Output ""
            Write-Output "Defender for Cloud Plan Status"
            Write-Output ""
            Write-Output "Enabled Plans ($($EnabledPlans.Count)):"
            foreach ($plan in $EnabledPlans) {
                Write-Output "    $plan"
            }

            if ($FailedPlans.Count -gt 0) {
                Write-Output "Failed Plans ($($FailedPlans.Count)):"
                foreach ($plan in $FailedPlans) {
                    Write-Output "    $plan"
                }
            }
        }

        "configurepolicies" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Security Policies" -Status "Configuring security policies and initiatives"

            $PolicyAssignments = Invoke-AzureOperation -Operation {
                Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" | Where-Object { $_.Properties.DisplayName -like "*Security Center*" -or $_.Properties.DisplayName -like "*Azure Security Benchmark*" }
            } -OperationName "Get Security Policy Assignments"

            Write-Output ""
            Write-Output "�� Current Security Policy Assignments"
            Write-Output ""

            foreach ($assignment in $PolicyAssignments) {
                $ComplianceState = Get-AzPolicyState -PolicyAssignmentName $assignment.Name -Top 1 | Select-Object -First 1
                $ComplianceStatus = if ($ComplianceState) { $ComplianceState.ComplianceState } else { "Unknown" }

                Write-Output " $($assignment.Properties.DisplayName)"
                Write-Output "Scope: $($assignment.Properties.Scope)"
                Write-Output "Compliance: $ComplianceStatus" -ForegroundColor $(if ($ComplianceStatus -eq "Compliant") { "Green" } elseif ($ComplianceStatus -eq "NonCompliant") { "Red" } else { "Yellow" })
                Write-Output ""
            }

            if ($EnableJITAccess -or $EnableFileIntegrityMonitoring -or $EnableAdaptiveApplicationControls) {
                Write-Log "Configuring security features..." -Level INFO

                $AutoProvisioningSettings = @{
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

            $SecurityScore = Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
                $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/secureScores?api-version=2020-01-01"

                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }

                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value | Select-Object -First 1
            } -OperationName "Get Security Score"

            $recommendations = Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
                $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/assessments?api-version=2020-01-01"

                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }

                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Security Recommendations"

            $CriticalFindings = $recommendations | Where-Object { $_.properties.status.severity -eq "High" -and $_.properties.status.code -eq "Unhealthy" }
            $MediumFindings = $recommendations | Where-Object { $_.properties.status.severity -eq "Medium" -and $_.properties.status.code -eq "Unhealthy" }
            $LowFindings = $recommendations | Where-Object { $_.properties.status.severity -eq "Low" -and $_.properties.status.code -eq "Unhealthy" }

            Write-Output ""
            Write-Output "Security Score Dashboard"
            Write-Output ""

            if ($SecurityScore) {
                $CurrentScore = [math]::Round(($SecurityScore.properties.score.current / $SecurityScore.properties.score.max) * 100, 1)
                $ScoreColor = if ($CurrentScore -ge 80) { "Green" } elseif ($CurrentScore -ge 60) { "Yellow" } else { "Red" }

                Write-Output "Overall Security Score: $CurrentScore% ($($SecurityScore.properties.score.current)/$($SecurityScore.properties.score.max))" -ForegroundColor $ScoreColor
                Write-Output ""
            }

            Write-Output "�� Security Findings by Severity:"
            Write-Output "    Critical (High): $($CriticalFindings.Count)"
            Write-Output "    Medium: $($MediumFindings.Count)"
            Write-Output "    Low: $($LowFindings.Count)"
            Write-Output ""

            if ($DetailedOutput -and $CriticalFindings.Count -gt 0) {
                Write-Output "�� Critical Security Issues (Top 10):"
                Write-Output ""
                $CriticalFindings | Select-Object -First 10 | ForEach-Object {
                    Write-Output " $($_.properties.displayName)"
                    Write-Output "Resource: $($_.properties.resourceDetails.id)"
                    Write-Output ""
                }
            }
        }

        "exportfindings" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Export Findings" -Status "Exporting security findings and recommendations"

            if (-not (Test-Path $ExportPath)) {
                New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
            }

            $SecurityData = Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id

                $AssessmentsUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/assessments?api-version=2020-01-01"

                $AlertsUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/alerts?api-version=2022-01-01"

                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }

                $assessments = (Invoke-RestMethod -Uri $AssessmentsUri -Method GET -Headers $headers).value
                $alerts = (Invoke-RestMethod -Uri $AlertsUri -Method GET -Headers $headers).value

                return @{
                    Assessments = $assessments
                    Alerts = $alerts
                    ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    SubscriptionId = $SubscriptionId
                }
            } -OperationName "Export Security Data"

            $JsonPath = Join-Path $ExportPath "defender-findings-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            $SecurityData | ConvertTo-Json -Depth 5 | Out-File -FilePath $JsonPath -Encoding UTF8

            $CsvData = $SecurityData.Assessments | ForEach-Object {
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

            $CsvPath = Join-Path $ExportPath "defender-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
            $CsvData | Export-Csv -Path $CsvPath -NoTypeInformation

            Write-Log "[OK] Security findings exported to: $ExportPath" -Level SUCCESS
            Write-Log "[OK] JSON export: $JsonPath" -Level INFO
            Write-Log "[OK] CSV summary: $CsvPath" -Level INFO
        }

        "configurealerts" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Alert Configuration" -Status "Configuring security alerts and notifications"

            if ($AlertEmails.Count -eq 0) {
                Write-Log "No alert emails provided - using current user email" -Level WARN
                $CurrentUser = (Get-AzContext).Account.Id
                $AlertEmails = @($CurrentUser)
            }

            $ContactParams = @{
                Email = $AlertEmails -join ";"
                Phone = ""
                AlertNotifications = "On"
                AlertsToAdmins = "On"
            }

            Invoke-AzureOperation -Operation {
                Set-AzSecurityContact -ErrorAction Stop @contactParams
            } -OperationName "Configure Security Contacts"

            Write-Log "[OK] Security contacts configured: $($AlertEmails -join ', ')" -Level SUCCESS

            if ($LogAnalyticsWorkspaceId) {
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityWorkspaceSetting -Name "default" -Scope "/subscriptions/$SubscriptionId" -WorkspaceId $LogAnalyticsWorkspaceId
                } -OperationName "Configure Log Analytics Workspace"

                Write-Log "[OK] Log Analytics workspace configured for security data collection" -Level SUCCESS
            }
        }

        "enableautoprovisioning" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Auto Provisioning" -Status "Enabling automatic provisioning of security agents"

            Invoke-AzureOperation -Operation {
                Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvisioning
            } -OperationName "Enable Auto Provisioning"

            Write-Log "[OK] Auto-provisioning enabled for security agents" -Level SUCCESS

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

    Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName "Plan Status" -Status "Checking current Defender for Cloud plan status"

    $CurrentPlans = Invoke-AzureOperation -Operation {
        Get-AzSecurityPricing -ErrorAction Stop
    } -OperationName "Get Current Defender Plans"

    $EnabledPlans = $CurrentPlans | Where-Object { $_.PricingTier -eq "Standard" }
    $FreePlans = $CurrentPlans | Where-Object { $_.PricingTier -eq "Free" }

    Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName "Recommendations" -Status "Analyzing security recommendations"

    $SecurityRecommendations = @(
        "Enable Defender for Cloud on all supported resource types",
        "Configure Log Analytics workspace for centralized logging",
        "Set up automated remediation for common security issues",
        "Enable Just-in-Time VM access for administrative access",
        "Configure network security groups with least privilege access",
        "Enable disk encryption for all virtual machines",
        "Implement Azure Key Vault for secrets management",
        "Configure backup and disaster recovery policies"
    )

    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName "Compliance" -Status "Evaluating compliance posture"

    $ComplianceStandards = @(
        "Azure Security Benchmark",
        "ISO 27001:2013",
        "SOC 2 Type 2",
        "PCI DSS 3.2.1",
        "NIST SP 800-53 Rev. 4",
        "HIPAA/HITECH"
    )

    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName "Cost Analysis" -Status "Estimating security costs"

    $CostEstimates = @{
        "Defender for Servers" = "~$15/server/month"
        "Defender for App Service" = "~$15/app service plan/month"
        "Defender for SQL" = "~$15/SQL server/month"
        "Defender for Storage" = "~$10/storage account/month"
        "Defender for Key Vault" = "~$2/vault/month"
        "Defender for Containers" = "~$7/vCore/month"
    }

    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName "Validation" -Status "Validating security configuration"

    $OverallSecurityScore = if ($EnabledPlans.Count -gt 0) {
        [math]::Round(($EnabledPlans.Count / $CurrentPlans.Count) * 100, 1)
    } else { 0 }

    Write-Output ""
    Write-Output ""
    Write-Output "                      MICROSOFT DEFENDER FOR CLOUD STATUS"
    Write-Output ""
    Write-Output ""

    Write-Output "Defender for Cloud Overview:"
    Write-Output "    Subscription: $SubscriptionId"
    Write-Output "    Plans Enabled: $($EnabledPlans.Count)/$($CurrentPlans.Count)" -ForegroundColor $(if ($EnabledPlans.Count -gt 0) { "Green" } else { "Red" })
    Write-Output "    Coverage Score: $OverallSecurityScore%" -ForegroundColor $(if ($OverallSecurityScore -ge 80) { "Green" } elseif ($OverallSecurityScore -ge 50) { "Yellow" } else { "Red" })

    if ($EnabledPlans.Count -gt 0) {
        Write-Output ""
        Write-Output "Enabled Protection Plans:"
        foreach ($plan in $EnabledPlans) {
            Write-Output "    $($plan.Name)"
        }
    }

    if ($FreePlans.Count -gt 0) {
        Write-Output ""
        Write-Output "[WARN]  Free Tier Plans (Consider Upgrading):"
        foreach ($plan in $FreePlans) {
            Write-Output "    $($plan.Name)"
        }
    }

    Write-Output ""
    Write-Output "Estimated Monthly Costs:"
    foreach ($cost in $CostEstimates.GetEnumerator()) {
        Write-Output "    $($cost.Key): $($cost.Value)"
    }

    Write-Output ""
    Write-Output "�� Security Recommendations:"
    foreach ($recommendation in $SecurityRecommendations) {
        Write-Output "   $recommendation"
    }

    Write-Output ""
    Write-Output "Compliance Standards Available:"
    foreach ($standard in $ComplianceStandards) {
        Write-Output "    $standard"
    }

    Write-Output ""
    Write-Output "�� Next Steps:"
    Write-Output "    Review and remediate high-priority security recommendations"
    Write-Output "    Configure custom security policies for your environment"
    Write-Output "    Set up regular security assessments and reporting"
    Write-Output "    Implement automated response to security incidents"
    Write-Output "    Train your team on security best practices"
    Write-Output ""

    Write-Log "Microsoft Defender for Cloud operation '$Action' completed successfully!" -Level SUCCESS

} catch {
    Write-Log "Microsoft Defender for Cloud operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception

    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify Security Center access permissions"
    Write-Output "    Check subscription eligibility for Defender plans"
    Write-Output "    Ensure Azure Security module is installed and updated"
    Write-Output "    Validate network connectivity to Azure Security endpoints"
    Write-Output ""

    throw
}

Write-Progress -Activity "Microsoft Defender for Cloud Management" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



