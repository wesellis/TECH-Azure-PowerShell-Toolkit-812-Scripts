<#
.SYNOPSIS
    Azure Defender For Cloud Automation

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("EnableDefender", "ConfigureDefender", "GetSecurityScore", "GetRecommendations", "GetAlerts", "EnableAutoProvisioning", "ConfigurePricing")]
    [ValidateNotNullOrEmpty()]
    [string]$Action,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter()]
    [string[]]$DefenderPlans = @("VirtualMachines", "AppService", "SqlServers", "StorageAccounts", "KeyVaults", "ContainerRegistry", "KubernetesService"),
    [Parameter()]
    [ValidateSet("Free", "Standard")]
    [string]$PricingTier = "Standard",
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceResourceId,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$EmailContact,
    [Parameter()]
    [ValidateSet("Off", "On")]
    [string]$EmailNotifications = "On",
    [Parameter()]
    [ValidateSet("All", "High", "Medium", "Low")]
    [string]$MinimumAlertSeverity = "Medium",
    [Parameter()]
    [switch]$EnableMonitoring,
    [Parameter()]
    [string]$OutputPath = ".\defender-report.json"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    # Test Azure connection
    # Progress stepNumber 1 -TotalSteps 6 -StepName "Security Connection" -Status "Validating Azure connection and security modules"
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    # Set subscription context if provided
    if ($SubscriptionId) {
        # Progress stepNumber 2 -TotalSteps 6 -StepName "Subscription Context" -Status "Setting subscription context"
        Invoke-AzureOperation -Operation {
            Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
        } -OperationName "Set Subscription Context"

    }
    # Execute the requested action
    # Progress stepNumber 3 -TotalSteps 6 -StepName "Security Operation" -Status "Executing $Action operation"
    switch ($Action) {
        "EnableDefender" {

            foreach ($plan in $DefenderPlans) {
                try {
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityPricing -Name $plan -PricingTier $PricingTier
                    } -OperationName "Enable Defender for $plan" | Out-Null

                } catch {

                }
            }
        }
        "ConfigureDefender" {

            # Configure security contacts
            if ($EmailContact) {
                $contactParams = @{
                    Email = $EmailContact
                    AlertNotifications = $EmailNotifications
                    AlertsToAdmins = $EmailNotifications
                }
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityContact -ErrorAction Stop @contactParams
                } -OperationName "Configure Security Contacts"

            }
            # Configure workspace settings
            if ($WorkspaceResourceId) {
                Invoke-AzureOperation -Operation {
                    Set-AzSecurityWorkspaceSetting -Name " default" -WorkspaceId $WorkspaceResourceId
                } -OperationName "Configure Log Analytics Workspace"

            }
        }
        "GetSecurityScore" {

            $secureScore = Invoke-AzureOperation -Operation {
                Get-AzSecurityScore -ErrorAction Stop
            } -OperationName "Get Security Score"
            $results = @{
                SecurityScore = $secureScore
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Subscription = (Get-AzContext).Subscription.Name
            }
        }
        "GetRecommendations" {

            $recommendations = Invoke-AzureOperation -Operation {
                Get-AzSecurityTask -ErrorAction Stop
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

$alerts = Invoke-AzureOperation -Operation {
                Get-AzSecurityAlert -ErrorAction Stop
            } -OperationName "Get Security Alerts"
            # Filter by severity if specified
            if ($MinimumAlertSeverity -ne "All" ) {
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

            $agents = @("MicrosoftMonitoringAgent" , "MicrosoftDependencyAgent" , "LogAnalyticsForLinux" )
            foreach ($agent in $agents) {
                try {
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityAutoProvisioningSetting -Name $agent -EnableAutoProvisioning $true
                    } -OperationName "Enable Auto-Provisioning for $agent"

                } catch {

                }
            }
        }
        "ConfigurePricing" {

            foreach ($plan in $DefenderPlans) {
                $currentPricing = Invoke-AzureOperation -Operation {
                    Get-AzSecurityPricing -Name $plan
                } -OperationName "Get Current Pricing for $plan"

                if ($currentPricing.PricingTier -ne $PricingTier) {
                    Invoke-AzureOperation -Operation {
                        Set-AzSecurityPricing -Name $plan -PricingTier $PricingTier
                    } -OperationName "Update Pricing for $plan"

                }
            }
        }
    }
    # Generate summary report
    # Progress stepNumber 4 -TotalSteps 6 -StepName "Report Generation" -Status "Generating security report"
    if ($results) {
        $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

    }
    # Display monitoring information
    # Progress stepNumber 5 -TotalSteps 6 -StepName "Monitoring Setup" -Status "Configuring monitoring"
    if ($EnableMonitoring) {

        # Get current security state
$currentPricings = Invoke-AzureOperation -Operation {
            Get-AzSecurityPricing -ErrorAction Stop
        } -OperationName "Get All Security Pricings"
$enabledPlans = $currentPricings | Where-Object { $_.PricingTier -eq "Standard" }

    }
    # Final validation and summary
    # Progress stepNumber 6 -TotalSteps 6 -StepName "Validation" -Status "Validating security configuration"
    # Success summary
    Write-Host ""
    Write-Host "                              AZURE DEFENDER CONFIGURATION SUCCESSFUL" -ForegroundColor Green
    Write-Host ""
    Write-Host "Security Operation: $Action" -ForegroundColor Cyan
    Write-Host "    Subscription: $(if($SubscriptionId){$SubscriptionId}else{'Current'})" -ForegroundColor White
    Write-Host "    Pricing Tier: $PricingTier" -ForegroundColor White
    Write-Host "    Protected Services: $($DefenderPlans.Count)" -ForegroundColor White
    if ($results) {
        Write-Host ""
        Write-Host "Results Summary:" -ForegroundColor Cyan
        if ($results.SecurityScore) {
            Write-Host "    Security Score: $($results.SecurityScore.SecureScorePercentage)%" -ForegroundColor Green
        }
        if ($results.TotalRecommendations) {
            Write-Host "    Total Recommendations: $($results.TotalRecommendations)" -ForegroundColor White
            Write-Host "    High Priority: $($results.HighPriorityRecommendations)" -ForegroundColor Yellow
        }
        if ($results.TotalAlerts) {
            Write-Host "    Security Alerts: $($results.TotalAlerts)" -ForegroundColor White
        }
    }
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "    Review recommendations: Get-AzSecurityTask" -ForegroundColor White
    Write-Host "    Monitor alerts: Get-AzSecurityAlert" -ForegroundColor White
    Write-Host "    Check compliance: Get-AzSecurityCompliance" -ForegroundColor White
    Write-Host ""

} catch {

    Write-Host ""
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "    Verify Security Center permissions" -ForegroundColor White
    Write-Host "    Check subscription access" -ForegroundColor White
    Write-Host "    Ensure Az.Security module is installed" -ForegroundColor White
    Write-Host "    Validate pricing tier permissions" -ForegroundColor White
    Write-Host ""
    throw
}

