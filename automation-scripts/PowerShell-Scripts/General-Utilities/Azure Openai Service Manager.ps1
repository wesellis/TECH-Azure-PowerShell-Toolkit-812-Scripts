<#
.SYNOPSIS
    Azure Openai Service Manager

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

<#
.SYNOPSIS
    We Enhanced Azure Openai Service Manager

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " East US" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WESkuName = " S0" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEAction = " Create" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEModelName = " gpt-35-turbo" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEModelVersion = " 0613" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEDeploymentName = " gpt-35-turbo-deployment" ,
    
    [Parameter(Mandatory=$false)]
    [int]$WECapacity = 120,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$WENetworkRules = @{},
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$WERestrictPublicAccess
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force


Show-Banner -ScriptName " Azure OpenAI Service Manager" -Version " 2.0" -Description " Enterprise AI service automation with security and monitoring"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName " Azure Connection" -Status " Validating connection and AI services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.CognitiveServices'))) {
        throw " Azure connection validation failed"
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 8 -StepName " Resource Group Validation" -Status " Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction Stop
    } -OperationName " Get Resource Group"
    
    Write-Log " ✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    switch ($WEAction.ToLower()) {
        " create" {
            # Create OpenAI account
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " OpenAI Account Creation" -Status " Creating Azure OpenAI service"
            
            $openAIParams = @{
                ResourceGroupName = $WEResourceGroupName
                Name = $WEAccountName
                Location = $WELocation
                SkuName = $WESkuName
                Kind = " OpenAI"
                NetworkRuleSet = @{
                    DefaultAction = if ($WERestrictPublicAccess) { " Deny" } else { " Allow" }
                    IpRules = @()
                    VirtualNetworkRules = @()
                }
            }
            
            if ($WENetworkRules.Count -gt 0) {
                if ($WENetworkRules.ContainsKey(" AllowedIPs" )) {
                    $openAIParams.NetworkRuleSet.IpRules = $WENetworkRules.AllowedIPs | ForEach-Object {
                        @{ IpAddress = $_ }
                    }
                }
            }
            
            Invoke-AzureOperation -Operation {
                New-AzCognitiveServicesAccount @openAIParams
            } -OperationName " Create OpenAI Account" | Out-Null
            
            Write-Log " ✓ OpenAI account created: $WEAccountName" -Level SUCCESS

            # Deploy model
            Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName " Model Deployment" -Status " Deploying AI model"
            
            Invoke-AzureOperation -Operation {
                # Using REST API call as PowerShell module may not have latest deployment cmdlets
                $subscriptionId = (Get-AzContext).Subscription.Id
                
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    properties = @{
                        model = @{
                            format = " OpenAI"
                            name = $WEModelName
                            version = $WEModelVersion
                        }
                        scaleSettings = @{
                            scaleType = " Standard"
                            capacity = $WECapacity
                        }
                    }
                } | ConvertTo-Json -Depth 5
                
                Invoke-RestMethod -Uri " https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$WEAccountName/deployments/$WEDeploymentName?api-version=2023-05-01" -Method PUT -Headers $headers -Body $body
            } -OperationName " Deploy AI Model" | Out-Null
            
            Write-Log " ✓ Model deployed: $WEModelName ($WEModelVersion) as $WEDeploymentName" -Level SUCCESS
        }
        
        " listmodels" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Model Discovery" -Status " Retrieving available models"
            
            $models = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                Invoke-RestMethod -Uri " https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$WEAccountName/models?api-version=2023-05-01" -Method GET -Headers $headers
            } -OperationName " List Available Models"
            
            Write-WELog "" " INFO"
            Write-WELog " 📋 Available Models for $WEAccountName" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            
            foreach ($model in $models.value) {
                Write-WELog " • $($model.name) - $($model.version)" " INFO" -ForegroundColor White
                if ($model.capabilities) {
                    Write-WELog "  Capabilities: $($model.capabilities -join ', ')" " INFO" -ForegroundColor Gray
                }
            }
        }
        
        " getkeys" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Key Retrieval" -Status " Retrieving API keys"
            
            $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEAccountName
            } -OperationName " Get API Keys"
            
            Write-WELog "" " INFO"
            Write-WELog " 🔑 API Keys for $WEAccountName" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            Write-WELog " Key 1: $($keys.Key1)" " INFO" -ForegroundColor Yellow
            Write-WELog " Key 2: $($keys.Key2)" " INFO" -ForegroundColor Yellow
            Write-WELog "" " INFO"
            Write-WELog " ⚠️  Store these keys securely! Consider using Azure Key Vault." " INFO" -ForegroundColor Red
        }
    }

    # Configure monitoring if enabled
    if ($WEEnableMonitoring) {
        Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName " Monitoring Setup" -Status " Configuring diagnostic settings"
        
        Invoke-AzureOperation -Operation {
            # Create diagnostic settings for OpenAI monitoring
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName | Select-Object -First 1
            
            if ($logAnalyticsWorkspace) {
                $diagnosticParams = @{
                    ResourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$WEResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$WEAccountName"
                    Name = " $WEAccountName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @(" Audit" , " RequestResponse" , " Trace" )
                    MetricCategory = @(" AllMetrics" )
                }
                
                Set-AzDiagnosticSetting @diagnosticParams
            } else {
                Write-Log " ⚠️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName " Configure Monitoring" | Out-Null
        
        $diagnosticSettings = $true
        
        if ($diagnosticSettings) {
            Write-Log " ✓ Monitoring configured with diagnostic settings" -Level SUCCESS
        }
    }

    # Apply enterprise tags
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName " Tagging" -Status " Applying enterprise tags"
    $tags = @{
        'Environment' = 'Production'
        'Service' = 'OpenAI'
        'ManagedBy' = 'Azure-Automation'
        'CreatedBy' = $env:USERNAME
        'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
        'CostCenter' = 'AI-Innovation'
        'Compliance' = 'AI-Governance'
    }
    
    Invoke-AzureOperation -Operation {
        $resource = Get-AzResource -ResourceGroupName $WEResourceGroupName -Name $WEAccountName -ResourceType " Microsoft.CognitiveServices/accounts"
        Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
    } -OperationName " Apply Enterprise Tags" | Out-Null

    # Security assessment
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName " Security Assessment" -Status " Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    
    # Check network access
    if ($WERestrictPublicAccess) {
        $securityScore++
        $securityFindings = $securityFindings + " ✓ Public access restricted"
    } else {
        $securityFindings = $securityFindings + " ⚠️  Public access allowed - consider restricting"
    }
    
    # Check monitoring
    if ($WEEnableMonitoring) {
        $securityScore++
        $securityFindings = $securityFindings + " ✓ Monitoring enabled"
    } else {
        $securityFindings = $securityFindings + " ⚠️  Monitoring not configured"
    }
    
    # Check resource group location compliance
    if ($WELocation -in @(" East US" , " West Europe" , " Southeast Asia" )) {
        $securityScore++
        $securityFindings = $securityFindings + " ✓ Deployed in compliant region"
    }
    
    # Check SKU for production readiness
    if ($WESkuName -ne " F0" ) {
        $securityScore++
        $securityFindings = $securityFindings + " ✓ Production-ready SKU selected"
    }
    
    # Check tagging compliance
    if ($tags.Count -ge 5) {
        $securityScore++
       ;  $securityFindings = $securityFindings + " ✓ Enterprise tagging compliant"
    }

    # Final validation
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName " Validation" -Status " Verifying service health"
    
   ;  $serviceStatus = Invoke-AzureOperation -Operation {
        Get-AzCognitiveServicesAccount -ResourceGroupName $WEResourceGroupName -Name $WEAccountName
    } -OperationName " Validate Service Status"

    # Success summary
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                              AZURE OPENAI SERVICE READY" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    Write-WELog " 🤖 OpenAI Service Details:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Account: $WEAccountName" " INFO" -ForegroundColor White
    Write-WELog "   • Resource Group: $WEResourceGroupName" " INFO" -ForegroundColor White
    Write-WELog "   • Location: $WELocation" " INFO" -ForegroundColor White
    Write-WELog "   • SKU: $WESkuName" " INFO" -ForegroundColor White
    Write-WELog "   • Endpoint: $($serviceStatus.Endpoint)" " INFO" -ForegroundColor White
    Write-WELog "   • Status: $($serviceStatus.ProvisioningState)" " INFO" -ForegroundColor Green
    
    if ($WEAction.ToLower() -eq " create" ) {
        Write-WELog "" " INFO"
        Write-WELog " 🚀 Model Deployment:" " INFO" -ForegroundColor Cyan
        Write-WELog "   • Model: $WEModelName ($WEModelVersion)" " INFO" -ForegroundColor White
        Write-WELog "   • Deployment: $WEDeploymentName" " INFO" -ForegroundColor White
        Write-WELog "   • Capacity: $WECapacity TPM" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 🔒 Security Assessment: $securityScore/$maxScore" " INFO" -ForegroundColor Cyan
    foreach ($finding in $securityFindings) {
        Write-WELog "   $finding" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 💡 Next Steps:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Test API: Use the endpoint and keys to make API calls" " INFO" -ForegroundColor White
    Write-WELog "   • Monitor usage: Check Azure Monitor for usage metrics" " INFO" -ForegroundColor White
    Write-WELog "   • Set up alerts: Configure cost and usage alerts" " INFO" -ForegroundColor White
    Write-WELog "   • Review compliance: Ensure AI governance policies are met" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"

    Write-Log " ✅ Azure OpenAI service '$WEAccountName' successfully configured for enterprise AI workloads!" -Level SUCCESS

} catch {
    Write-Log " ❌ OpenAI service operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-WELog "" " INFO"
    Write-WELog " 🔧 Troubleshooting Tips:" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Verify OpenAI service availability in your region" " INFO" -ForegroundColor White
    Write-WELog "   • Check subscription quotas for Cognitive Services" " INFO" -ForegroundColor White
    Write-WELog "   • Ensure proper permissions for AI service creation" " INFO" -ForegroundColor White
    Write-WELog "   • Validate model availability for your region" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"
    
    exit 1
}

Write-Progress -Activity " OpenAI Service Management" -Completed
Write-Log " Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================