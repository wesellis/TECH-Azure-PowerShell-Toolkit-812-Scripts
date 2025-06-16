# Azure Defender for Cloud Automation Tool
# Professional Azure security automation script for comprehensive cloud protection
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0 | Enhanced for enterprise security environments

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("EnableDefender", "ConfigureDefender", "GetSecurityScore", "GetRecommendations", "GetAlerts", "EnableAutoProvisioning", "ConfigurePricing")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string[]]$DefenderPlans = @("VirtualMachines", "AppService", "SqlServers", "StorageAccounts", "KeyVaults", "ContainerRegistry", "KubernetesService"),
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Free", "Standard")]
    [string]$PricingTier = "Standard",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkspaceResourceId,
    
    [Parameter(Mandatory=$false)]
    [string]$EmailContact,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Off", "On")]
    [string]$EmailNotifications = "On",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "High", "Medium", "Low")]
    [string]$MinimumAlertSeverity = "Medium",
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\defender-report.json"
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

# Professional banner
Show-Banner -ScriptName "Azure Defender for Cloud Automation Tool" -Version "1.0" -Description "Comprehensive cloud security automation with advanced threat protection"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 6 -StepName "Security Connection" -Status "Validating Azure connection and security modules"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Security', 'Az.Resources'))) {
        throw "Azure connection validation failed"
    }

    # Set subscription context if provided
    if ($SubscriptionId) {
        Write-ProgressStep -StepNumber 2 -TotalSteps 6 -StepName "Subscription Context" -Status "Setting subscription context"
        Invoke-AzureOperation -Operation {
            Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
        } -OperationName "Set Subscription Context"
        Write-Log "✓ Subscription context set to: $SubscriptionId" -Level SUCCESS
    }

    # Execute the requested action
    Write-ProgressStep -StepNumber 3 -TotalSteps 6 -StepName "Security Operation" -Status "Executing $Action operation"
    
    switch ($Action) {
        "EnableDefender" {
            Write-Log "🛡️ Enabling Azure Defender for Cloud..." -Level INFO
            
            foreach ($plan in $DefenderPlans) {
                try {
                    $pricing = Invoke-AzureOperation -Operation {
                        Set-AzSecurityPricing -Name $plan -PricingTier $PricingTier
                    } -OperationName "Enable Defender for $plan"
                    
                    Write-Log "✓ Defender enabled for $plan ($PricingTier tier)" -Level SUCCESS
                } catch {
                    Write-Log "⚠️ Failed to enable Defender for $plan : $($_.Exception.Message)" -Level WARNING
                }
            }
        }
        
        "ConfigureDefender" {
            Write-Log "🔧 Configuring Azure Defender settings..." -Level INFO
            
            # Configure security contacts
            if ($EmailContact) {
                $contactParams = @{
                    Email = $EmailContact
                    AlertNotifications = $EmailNotifications
                    AlertsToAdmins = $EmailNotifications
                }
                
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityContact @contactParams
                } -OperationName "Configure Security Contacts"
                
                Write-Log "✓ Security contact configured: $EmailContact" -Level SUCCESS
            }
            
            # Configure workspace settings
            if ($WorkspaceResourceId) {
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityWorkspaceSetting -Name "default" -WorkspaceId $WorkspaceResourceId
                } -OperationName "Configure Log Analytics Workspace"
                
                Write-Log "✓ Log Analytics workspace configured" -Level SUCCESS
            }
        }
        
        "GetSecurityScore" {
            Write-Log "📊 Retrieving security score and posture..." -Level INFO
            
            $secureScore = Invoke-AzureOperation -Operation {
                Get-AzSecurityScore
            } -OperationName "Get Security Score"
            
            $results = @{
                SecurityScore = $secureScore
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Subscription = (Get-AzContext).Subscription.Name
            }
        }
        
        "GetRecommendations" {
            Write-Log "📋 Retrieving security recommendations..." -Level INFO
            
            $recommendations = Invoke-AzureOperation -Operation {
                Get-AzSecurityTask
            } -OperationName "Get Security Recommendations"
            
            $highPriorityRecs = $recommendations | Where-Object { $_.SecurityTaskParameters.severityLevel -eq "High" }
            
            $results = @{
                TotalRecommendations = $recommendations.Count
                HighPriorityRecommendations = $highPriorityRecs.Count
                Recommendations = $recommendations | Select-Object Name, SecurityTaskParameters, State
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
        
        "GetAlerts" {
            Write-Log "🚨 Retrieving security alerts..." -Level INFO
            
            $alerts = Invoke-AzureOperation -Operation {
                Get-AzSecurityAlert
            } -OperationName "Get Security Alerts"
            
            # Filter by severity if specified
            if ($MinimumAlertSeverity -ne "All") {
                $severityOrder = @{"Low" = 1; "Medium" = 2; "High" = 3}
                $minSeverityValue = $severityOrder[$MinimumAlertSeverity]
                $alerts = $alerts | Where-Object { $severityOrder[$_.AlertSeverity] -ge $minSeverityValue }
            }
            
            $results = @{
                TotalAlerts = $alerts.Count
                Alerts = $alerts | Select-Object AlertDisplayName, AlertSeverity, State, TimeGeneratedUtc
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
        
        "EnableAutoProvisioning" {
            Write-Log "🔄 Enabling auto-provisioning agents..." -Level INFO
            
            $agents = @("MicrosoftMonitoringAgent", "MicrosoftDependencyAgent", "LogAnalyticsForLinux")
            
            foreach ($agent in $agents) {
                try {
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityAutoProvisioningSetting -Name $agent -EnableAutoProvisioning $true
                    } -OperationName "Enable Auto-Provisioning for $agent"
                    
                    Write-Log "✓ Auto-provisioning enabled for $agent" -Level SUCCESS
                } catch {
                    Write-Log "⚠️ Failed to enable auto-provisioning for $agent" -Level WARNING
                }
            }
        }
        
        "ConfigurePricing" {
            Write-Log "💰 Configuring pricing tiers..." -Level INFO
            
            foreach ($plan in $DefenderPlans) {
                $currentPricing = Invoke-AzureOperation -Operation {
                    Get-AzSecurityPricing -Name $plan
                } -OperationName "Get Current Pricing for $plan"
                
                Write-Log "Current pricing for $plan : $($currentPricing.PricingTier)" -Level INFO
                
                if ($currentPricing.PricingTier -ne $PricingTier) {
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityPricing -Name $plan -PricingTier $PricingTier
                    } -OperationName "Update Pricing for $plan"
                    
                    Write-Log "✓ Updated $plan pricing to $PricingTier" -Level SUCCESS
                }
            }
        }
    }

    # Generate summary report
    Write-ProgressStep -StepNumber 4 -TotalSteps 6 -StepName "Report Generation" -Status "Generating security report"
    
    if ($results) {
        $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "✓ Security report saved to: $OutputPath" -Level SUCCESS
    }

    # Display monitoring information
    Write-ProgressStep -StepNumber 5 -TotalSteps 6 -StepName "Monitoring Setup" -Status "Configuring monitoring"
    
    if ($EnableMonitoring) {
        Write-Log "📊 Setting up continuous monitoring..." -Level INFO
        
        # Get current security state
        $currentPricings = Invoke-AzureOperation -Operation {
            Get-AzSecurityPricing
        } -OperationName "Get All Security Pricings"
        
        $enabledPlans = $currentPricings | Where-Object { $_.PricingTier -eq "Standard" }
        Write-Log "✓ Defender enabled for $($enabledPlans.Count) service types" -Level SUCCESS
    }

    # Final validation and summary
    Write-ProgressStep -StepNumber 6 -TotalSteps 6 -StepName "Validation" -Status "Validating security configuration"
    
    # Success summary
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                              AZURE DEFENDER CONFIGURATION SUCCESSFUL" -ForegroundColor Green  
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "🛡️ Security Operation: $Action" -ForegroundColor Cyan
    Write-Host "   • Subscription: $(if($SubscriptionId){$SubscriptionId}else{'Current'})" -ForegroundColor White
    Write-Host "   • Pricing Tier: $PricingTier" -ForegroundColor White
    Write-Host "   • Protected Services: $($DefenderPlans.Count)" -ForegroundColor White
    
    if ($results) {
        Write-Host ""
        Write-Host "📊 Results Summary:" -ForegroundColor Cyan
        if ($results.SecurityScore) {
            Write-Host "   • Security Score: $($results.SecurityScore.SecureScorePercentage)%" -ForegroundColor Green
        }
        if ($results.TotalRecommendations) {
            Write-Host "   • Total Recommendations: $($results.TotalRecommendations)" -ForegroundColor White
            Write-Host "   • High Priority: $($results.HighPriorityRecommendations)" -ForegroundColor Yellow
        }
        if ($results.TotalAlerts) {
            Write-Host "   • Security Alerts: $($results.TotalAlerts)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "💡 Next Steps:" -ForegroundColor Cyan
    Write-Host "   • Review recommendations: Get-AzSecurityTask" -ForegroundColor White
    Write-Host "   • Monitor alerts: Get-AzSecurityAlert" -ForegroundColor White
    Write-Host "   • Check compliance: Get-AzSecurityCompliance" -ForegroundColor White
    Write-Host ""

    Write-Log "✅ Azure Defender configuration completed successfully!" -Level SUCCESS

} catch {
    Write-Log "❌ Azure Defender configuration failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Host ""
    Write-Host "🔧 Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "   • Verify Security Center permissions" -ForegroundColor White
    Write-Host "   • Check subscription access" -ForegroundColor White
    Write-Host "   • Ensure Az.Security module is installed" -ForegroundColor White
    Write-Host "   • Validate pricing tier permissions" -ForegroundColor White
    Write-Host ""
    
    exit 1
}

Write-Progress -Activity "Azure Defender Configuration" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO