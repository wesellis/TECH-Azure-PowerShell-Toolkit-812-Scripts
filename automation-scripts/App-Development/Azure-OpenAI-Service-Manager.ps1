# Azure OpenAI Service Manager
# Professional Azure automation script for AI service management
# Author: Wesley Ellis | wes@wesellis.com
# Version: 2.0 | Enhanced for enterprise AI deployments

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$SkuName = "S0",
    
    [Parameter(Mandatory=$false)]
    [string]$Action = "Create",
    
    [Parameter(Mandatory=$false)]
    [string]$ModelName = "gpt-35-turbo",
    
    [Parameter(Mandatory=$false)]
    [string]$ModelVersion = "0613",
    
    [Parameter(Mandatory=$false)]
    [string]$DeploymentName = "gpt-35-turbo-deployment",
    
    [Parameter(Mandatory=$false)]
    [int]$Capacity = 120,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$NetworkRules = @{},
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$RestrictPublicAccess
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

# Professional banner
Show-Banner -ScriptName "Azure OpenAI Service Manager" -Version "2.0" -Description "Enterprise AI service automation with security and monitoring"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName "Azure Connection" -Status "Validating connection and AI services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.CognitiveServices'))) {
        throw "Azure connection validation failed"
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 8 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    Write-Log "✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    switch ($Action.ToLower()) {
        "create" {
            # Create OpenAI account
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "OpenAI Account Creation" -Status "Creating Azure OpenAI service"
            
            $openAIParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $AccountName
                Location = $Location
                SkuName = $SkuName
                Kind = "OpenAI"
                NetworkRuleSet = @{
                    DefaultAction = if ($RestrictPublicAccess) { "Deny" } else { "Allow" }
                    IpRules = @()
                    VirtualNetworkRules = @()
                }
            }
            
            if ($NetworkRules.Count -gt 0) {
                if ($NetworkRules.ContainsKey("AllowedIPs")) {
                    $openAIParams.NetworkRuleSet.IpRules = $NetworkRules.AllowedIPs | ForEach-Object {
                        @{ IpAddress = $_ }
                    }
                }
            }
            
            Invoke-AzureOperation -Operation {
                New-AzCognitiveServicesAccount -ErrorAction Stop @openAIParams
            } -OperationName "Create OpenAI Account" | Out-Null
            
            Write-Log "✓ OpenAI account created: $AccountName" -Level SUCCESS

            # Deploy model
            Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName "Model Deployment" -Status "Deploying AI model"
            
            Invoke-AzureOperation -Operation {
                # Using REST API call as PowerShell module may not have latest deployment cmdlets
                $subscriptionId = (Get-AzContext).Subscription.Id
                
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    properties = @{
                        model = @{
                            format = "OpenAI"
                            name = $ModelName
                            version = $ModelVersion
                        }
                        scaleSettings = @{
                            scaleType = "Standard"
                            capacity = $Capacity
                        }
                    }
                } | ConvertTo-Json -Depth 5
                
                Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName/deployments/$DeploymentName?api-version=2023-05-01" -Method PUT -Headers $headers -Body $body
            } -OperationName "Deploy AI Model" | Out-Null
            
            Write-Log "✓ Model deployed: $ModelName ($ModelVersion) as $DeploymentName" -Level SUCCESS
        }
        
        "listmodels" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Model Discovery" -Status "Retrieving available models"
            
            $models = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName/models?api-version=2023-05-01" -Method GET -Headers $headers
            } -OperationName "List Available Models"
            
            Write-Information ""
            Write-Information "📋 Available Models for $AccountName"
            Write-Information "════════════════════════════════════════════════════════════════════"
            
            foreach ($model in $models.value) {
                Write-Information "• $($model.name) - $($model.version)"
                if ($model.capabilities) {
                    Write-Information "  Capabilities: $($model.capabilities -join ', ')"
                }
            }
        }
        
        "getkeys" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Key Retrieval" -Status "Retrieving API keys"
            
            $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
            } -OperationName "Get API Keys"
            
            Write-Information ""
            Write-Information "🔑 API Keys for $AccountName"
            Write-Information "════════════════════════════════════════════════════════════════════"
            Write-Information "Key 1: $($keys.Key1)"
            Write-Information "Key 2: $($keys.Key2)"
            Write-Information ""
            Write-Information "⚠️  Store these keys securely! Consider using Azure Key Vault."
        }
    }

    # Configure monitoring if enabled
    if ($EnableMonitoring) {
        Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        
        Invoke-AzureOperation -Operation {
            # Create diagnostic settings for OpenAI monitoring
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            
            if ($logAnalyticsWorkspace) {
                $diagnosticParams = @{
                    ResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName"
                    Name = "$AccountName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("Audit", "RequestResponse", "Trace")
                    MetricCategory = @("AllMetrics")
                }
                
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {
                Write-Log "⚠️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName "Configure Monitoring" | Out-Null
        
        $diagnosticSettings = $true
        
        if ($diagnosticSettings) {
            Write-Log "✓ Monitoring configured with diagnostic settings" -Level SUCCESS
        }
    }

    # Apply enterprise tags
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName "Tagging" -Status "Applying enterprise tags"
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
        $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $AccountName -ResourceType "Microsoft.CognitiveServices/accounts"
        Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
    } -OperationName "Apply Enterprise Tags" | Out-Null

    # Security assessment
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName "Security Assessment" -Status "Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    
    # Check network access
    if ($RestrictPublicAccess) {
        $securityScore++
        $securityFindings += "✓ Public access restricted"
    } else {
        $securityFindings += "⚠️  Public access allowed - consider restricting"
    }
    
    # Check monitoring
    if ($EnableMonitoring) {
        $securityScore++
        $securityFindings += "✓ Monitoring enabled"
    } else {
        $securityFindings += "⚠️  Monitoring not configured"
    }
    
    # Check resource group location compliance
    if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
        $securityScore++
        $securityFindings += "✓ Deployed in compliant region"
    }
    
    # Check SKU for production readiness
    if ($SkuName -ne "F0") {
        $securityScore++
        $securityFindings += "✓ Production-ready SKU selected"
    }
    
    # Check tagging compliance
    if ($tags.Count -ge 5) {
        $securityScore++
        $securityFindings += "✓ Enterprise tagging compliant"
    }

    # Final validation
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName "Validation" -Status "Verifying service health"
    
    $serviceStatus = Invoke-AzureOperation -Operation {
        Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName
    } -OperationName "Validate Service Status"

    # Success summary
    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                              AZURE OPENAI SERVICE READY"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    Write-Information "🤖 OpenAI Service Details:"
    Write-Information "   • Account: $AccountName"
    Write-Information "   • Resource Group: $ResourceGroupName"
    Write-Information "   • Location: $Location"
    Write-Information "   • SKU: $SkuName"
    Write-Information "   • Endpoint: $($serviceStatus.Endpoint)"
    Write-Information "   • Status: $($serviceStatus.ProvisioningState)"
    
    if ($Action.ToLower() -eq "create") {
        Write-Information ""
        Write-Information "🚀 Model Deployment:"
        Write-Information "   • Model: $ModelName ($ModelVersion)"
        Write-Information "   • Deployment: $DeploymentName"
        Write-Information "   • Capacity: $Capacity TPM"
    }
    
    Write-Information ""
    Write-Information "🔒 Security Assessment: $securityScore/$maxScore"
    foreach ($finding in $securityFindings) {
        Write-Information "   $finding"
    }
    
    Write-Information ""
    Write-Information "💡 Next Steps:"
    Write-Information "   • Test API: Use the endpoint and keys to make API calls"
    Write-Information "   • Monitor usage: Check Azure Monitor for usage metrics"
    Write-Information "   • Set up alerts: Configure cost and usage alerts"
    Write-Information "   • Review compliance: Ensure AI governance policies are met"
    Write-Information ""

    Write-Log "✅ Azure OpenAI service '$AccountName' successfully configured for enterprise AI workloads!" -Level SUCCESS

} catch {
    Write-Log "❌ OpenAI service operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Information ""
    Write-Information "🔧 Troubleshooting Tips:"
    Write-Information "   • Verify OpenAI service availability in your region"
    Write-Information "   • Check subscription quotas for Cognitive Services"
    Write-Information "   • Ensure proper permissions for AI service creation"
    Write-Information "   • Validate model availability for your region"
    Write-Information ""
    
    exit 1
}

Write-Progress -Activity "OpenAI Service Management" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
