<#
.SYNOPSIS
    We Enhanced Azure Defender For Cloud Automation

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(" EnableDefender", " ConfigureDefender", " GetSecurityScore", " GetRecommendations", " GetAlerts", " EnableAutoProvisioning", " ConfigurePricing")]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string[]]$WEDefenderPlans = @(" VirtualMachines", " AppService", " SqlServers", " StorageAccounts", " KeyVaults", " ContainerRegistry", " KubernetesService"),
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Free", " Standard")]
    [string]$WEPricingTier = " Standard",
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEWorkspaceResourceId,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEmailContact,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Off", " On")]
    [string]$WEEmailNotifications = " On",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" All", " High", " Medium", " Low")]
    [string]$WEMinimumAlertSeverity = " Medium",
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " .\defender-report.json"
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force


Show-Banner -ScriptName " Azure Defender for Cloud Automation Tool" -Version " 1.0" -Description " Comprehensive cloud security automation with advanced threat protection"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 6 -StepName " Security Connection" -Status " Validating Azure connection and security modules"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Security', 'Az.Resources'))) {
        throw " Azure connection validation failed"
    }

    # Set subscription context if provided
    if ($WESubscriptionId) {
        Write-ProgressStep -StepNumber 2 -TotalSteps 6 -StepName " Subscription Context" -Status " Setting subscription context"
        Invoke-AzureOperation -Operation {
            Set-AzContext -SubscriptionId $WESubscriptionId -ErrorAction Stop
        } -OperationName " Set Subscription Context"
        Write-Log " ✓ Subscription context set to: $WESubscriptionId" -Level SUCCESS
    }

    # Execute the requested action
    Write-ProgressStep -StepNumber 3 -TotalSteps 6 -StepName " Security Operation" -Status " Executing $WEAction operation"
    
    switch ($WEAction) {
        " EnableDefender" {
            Write-Log " 🛡️ Enabling Azure Defender for Cloud..." -Level INFO
            
            foreach ($plan in $WEDefenderPlans) {
                try {
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityPricing -Name $plan -PricingTier $WEPricingTier
                    } -OperationName " Enable Defender for $plan" | Out-Null
                    
                    Write-Log " ✓ Defender enabled for $plan ($WEPricingTier tier)" -Level SUCCESS
                } catch {
                    Write-Log " ⚠️ Failed to enable Defender for $plan : $($_.Exception.Message)" -Level WARNING
                }
            }
        }
        
        " ConfigureDefender" {
            Write-Log " 🔧 Configuring Azure Defender settings..." -Level INFO
            
            # Configure security contacts
            if ($WEEmailContact) {
                $contactParams = @{
                    Email = $WEEmailContact
                    AlertNotifications = $WEEmailNotifications
                    AlertsToAdmins = $WEEmailNotifications
                }
                
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityContact @contactParams
                } -OperationName " Configure Security Contacts"
                
                Write-Log " ✓ Security contact configured: $WEEmailContact" -Level SUCCESS
            }
            
            # Configure workspace settings
            if ($WEWorkspaceResourceId) {
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityWorkspaceSetting -Name " default" -WorkspaceId $WEWorkspaceResourceId
                } -OperationName " Configure Log Analytics Workspace"
                
                Write-Log " ✓ Log Analytics workspace configured" -Level SUCCESS
            }
        }
        
        " GetSecurityScore" {
            Write-Log " 📊 Retrieving security score and posture..." -Level INFO
            
            $secureScore = Invoke-AzureOperation -Operation {
                Get-AzSecurityScore
            } -OperationName " Get Security Score"
            
            $results = @{
                SecurityScore = $secureScore
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Subscription = (Get-AzContext).Subscription.Name
            }
        }
        
        " GetRecommendations" {
            Write-Log " 📋 Retrieving security recommendations..." -Level INFO
            
            $recommendations = Invoke-AzureOperation -Operation {
                Get-AzSecurityTask
            } -OperationName " Get Security Recommendations"
            
            $highPriorityRecs = $recommendations | Where-Object { $_.SecurityTaskParameters.severityLevel -eq " High" }
            
            $results = @{
                TotalRecommendations = $recommendations.Count
                HighPriorityRecommendations = $highPriorityRecs.Count
                Recommendations = $recommendations | Select-Object Name, SecurityTaskParameters, State
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
        
        " GetAlerts" {
            Write-Log " 🚨 Retrieving security alerts..." -Level INFO
            
            $alerts = Invoke-AzureOperation -Operation {
                Get-AzSecurityAlert
            } -OperationName " Get Security Alerts"
            
            # Filter by severity if specified
            if ($WEMinimumAlertSeverity -ne " All") {
               ;  $severityOrder = @{" Low" = 1; " Medium" = 2; " High" = 3}
                $minSeverityValue = $severityOrder[$WEMinimumAlertSeverity]
                $alerts = $alerts | Where-Object { $severityOrder[$_.AlertSeverity] -ge $minSeverityValue }
            }
            
            $results = @{
                TotalAlerts = $alerts.Count
                Alerts = $alerts | Select-Object AlertDisplayName, AlertSeverity, State, TimeGeneratedUtc
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
        
        " EnableAutoProvisioning" {
            Write-Log " 🔄 Enabling auto-provisioning agents..." -Level INFO
            
            $agents = @(" MicrosoftMonitoringAgent", " MicrosoftDependencyAgent", " LogAnalyticsForLinux")
            
            foreach ($agent in $agents) {
                try {
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityAutoProvisioningSetting -Name $agent -EnableAutoProvisioning $true
                    } -OperationName " Enable Auto-Provisioning for $agent"
                    
                    Write-Log " ✓ Auto-provisioning enabled for $agent" -Level SUCCESS
                } catch {
                    Write-Log " ⚠️ Failed to enable auto-provisioning for $agent" -Level WARNING
                }
            }
        }
        
        " ConfigurePricing" {
            Write-Log " 💰 Configuring pricing tiers..." -Level INFO
            
            foreach ($plan in $WEDefenderPlans) {
                $currentPricing = Invoke-AzureOperation -Operation {
                    Get-AzSecurityPricing -Name $plan
                } -OperationName " Get Current Pricing for $plan"
                
                Write-Log " Current pricing for $plan : $($currentPricing.PricingTier)" -Level INFO
                
                if ($currentPricing.PricingTier -ne $WEPricingTier) {
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityPricing -Name $plan -PricingTier $WEPricingTier
                    } -OperationName " Update Pricing for $plan"
                    
                    Write-Log " ✓ Updated $plan pricing to $WEPricingTier" -Level SUCCESS
                }
            }
        }
    }

    # Generate summary report
    Write-ProgressStep -StepNumber 4 -TotalSteps 6 -StepName " Report Generation" -Status " Generating security report"
    
    if ($results) {
        $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $WEOutputPath -Encoding UTF8
        Write-Log " ✓ Security report saved to: $WEOutputPath" -Level SUCCESS
    }

    # Display monitoring information
    Write-ProgressStep -StepNumber 5 -TotalSteps 6 -StepName " Monitoring Setup" -Status " Configuring monitoring"
    
    if ($WEEnableMonitoring) {
        Write-Log " 📊 Setting up continuous monitoring..." -Level INFO
        
        # Get current security state
        $currentPricings = Invoke-AzureOperation -Operation {
            Get-AzSecurityPricing
        } -OperationName " Get All Security Pricings"
        
       ;  $enabledPlans = $currentPricings | Where-Object { $_.PricingTier -eq " Standard" }
        Write-Log " ✓ Defender enabled for $($enabledPlans.Count) service types" -Level SUCCESS
    }

    # Final validation and summary
    Write-ProgressStep -StepNumber 6 -TotalSteps 6 -StepName " Validation" -Status " Validating security configuration"
    
    # Success summary
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                              AZURE DEFENDER CONFIGURATION SUCCESSFUL" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    Write-WELog " 🛡️ Security Operation: $WEAction" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Subscription: $(if($WESubscriptionId){$WESubscriptionId}else{'Current'})" " INFO" -ForegroundColor White
    Write-WELog "   • Pricing Tier: $WEPricingTier" " INFO" -ForegroundColor White
    Write-WELog "   • Protected Services: $($WEDefenderPlans.Count)" " INFO" -ForegroundColor White
    
    if ($results) {
        Write-WELog "" " INFO"
        Write-WELog " 📊 Results Summary:" " INFO" -ForegroundColor Cyan
        if ($results.SecurityScore) {
            Write-WELog "   • Security Score: $($results.SecurityScore.SecureScorePercentage)%" " INFO" -ForegroundColor Green
        }
        if ($results.TotalRecommendations) {
            Write-WELog "   • Total Recommendations: $($results.TotalRecommendations)" " INFO" -ForegroundColor White
            Write-WELog "   • High Priority: $($results.HighPriorityRecommendations)" " INFO" -ForegroundColor Yellow
        }
        if ($results.TotalAlerts) {
            Write-WELog "   • Security Alerts: $($results.TotalAlerts)" " INFO" -ForegroundColor White
        }
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 💡 Next Steps:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Review recommendations: Get-AzSecurityTask" " INFO" -ForegroundColor White
    Write-WELog "   • Monitor alerts: Get-AzSecurityAlert" " INFO" -ForegroundColor White
    Write-WELog "   • Check compliance: Get-AzSecurityCompliance" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"

    Write-Log " ✅ Azure Defender configuration completed successfully!" -Level SUCCESS

} catch {
    Write-Log " ❌ Azure Defender configuration failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-WELog "" " INFO"
    Write-WELog " 🔧 Troubleshooting Tips:" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Verify Security Center permissions" " INFO" -ForegroundColor White
    Write-WELog "   • Check subscription access" " INFO" -ForegroundColor White
    Write-WELog "   • Ensure Az.Security module is installed" " INFO" -ForegroundColor White
    Write-WELog "   • Validate pricing tier permissions" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"
    
    exit 1
}

Write-Progress -Activity " Azure Defender Configuration" -Completed
Write-Log " Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================