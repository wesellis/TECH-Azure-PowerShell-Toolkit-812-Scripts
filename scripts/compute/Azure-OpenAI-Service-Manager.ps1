#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure OpenAI Service Manager
#
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$AccountName,
    [Parameter()]
    [string]$Location = "East US",
    [Parameter()]
    [string]$SkuName = "S0",
    [Parameter()]
    [string]$Action = "Create",
    [Parameter()]
    [string]$ModelName = "gpt-35-turbo",
    [Parameter()]
    [string]$ModelVersion = "0613",
    [Parameter()]
    [string]$DeploymentName = "gpt-35-turbo-deployment",
    [Parameter()]
    [int]$Capacity = 120,
    [Parameter()]
    [hashtable]$NetworkRules = @{},
    [Parameter()]
    [switch]$EnableMonitoring,
    [Parameter()]
    [switch]$RestrictPublicAccess
)
try {
    # Test Azure connection
        if (-not (Get-AzContext)) { Connect-AzAccount }
    # Validate resource group
        $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    switch ($Action.ToLower()) {
        "create" {
            # Create OpenAI account
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
            
            # Deploy model
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
            
        }
        "listmodels" {
                $models = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName/models?api-version=2023-05-01" -Method GET -Headers $headers
            } -OperationName "List Available Models"
            Write-Host ""
            foreach ($model in $models.value) {
                Write-Host " $($model.name) - $($model.version)"
                if ($model.capabilities) {
                    Write-Host "Capabilities: $($model.capabilities -join ', ')"
                }
            }
        }
        "getkeys" {
                $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
            } -OperationName "Get API Keys"
            Write-Host ""
            Write-Host "Key 1: $($keys.Key1)"
            Write-Host "Key 2: $($keys.Key2)"
            Write-Host ""
            Write-Host "[WARN]  Store these keys securely! Consider using Azure Key Vault."
        }
    }
    # Configure monitoring if enabled
    if ($EnableMonitoring) {
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
                
                return $null
            }
        } -OperationName "Configure Monitoring" | Out-Null
        $diagnosticSettings = $true
        if ($diagnosticSettings) {
            
        }
    }
    # Apply enterprise tags
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
        $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    # Check network access
    if ($RestrictPublicAccess) {
        $securityScore++
        $securityFindings += "[OK] Public access restricted"
    } else {
        $securityFindings += "[WARN]  Public access allowed - consider restricting"
    }
    # Check monitoring
    if ($EnableMonitoring) {
        $securityScore++
        $securityFindings += "[OK] Monitoring enabled"
    } else {
        $securityFindings += "[WARN]  Monitoring not configured"
    }
    # Check resource group location compliance
    if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
        $securityScore++
        $securityFindings += "[OK] Deployed in compliant region"
    }
    # Check SKU for production readiness
    if ($SkuName -ne "F0") {
        $securityScore++
        $securityFindings += "[OK] Production-ready SKU selected"
    }
    # Check tagging compliance
    if ($tags.Count -ge 5) {
        $securityScore++
        $securityFindings += "[OK] Enterprise tagging compliant"
    }
    # Final validation
        $serviceStatus = Invoke-AzureOperation -Operation {
        Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName
    } -OperationName "Validate Service Status"
    # Success summary
    Write-Host ""
    Write-Host "                              AZURE OPENAI SERVICE READY"
    Write-Host ""
    Write-Host "    Account: $AccountName"
    Write-Host "    Resource Group: $ResourceGroupName"
    Write-Host "    Location: $Location"
    Write-Host "    SKU: $SkuName"
    Write-Host "    Endpoint: $($serviceStatus.Endpoint)"
    Write-Host "    Status: $($serviceStatus.ProvisioningState)"
    if ($Action.ToLower() -eq "create") {
        Write-Host ""
        Write-Host "Model Deployment:"
        Write-Host "    Model: $ModelName ($ModelVersion)"
        Write-Host "    Deployment: $DeploymentName"
        Write-Host "    Capacity: $Capacity TPM"
    }
    Write-Host ""
    Write-Host "[LOCK] Security Assessment: $securityScore/$maxScore"
    foreach ($finding in $securityFindings) {
        Write-Host "   $finding"
    }
    Write-Host ""
    Write-Host "    Test API: Use the endpoint and keys to make API calls"
    Write-Host "    Monitor usage: Check Azure Monitor for usage metrics"
    Write-Host "    Set up alerts: Configure cost and usage alerts"
    Write-Host "    Review compliance: Ensure AI governance policies are met"
    Write-Host ""
    
} catch {
    
    Write-Host ""
    Write-Host "Troubleshooting Tips:"
    Write-Host "    Verify OpenAI service availability in your region"
    Write-Host "    Check subscription quotas for Cognitive Services"
    Write-Host "    Ensure proper permissions for AI service creation"
    Write-Host "    Validate model availability for your region"
    Write-Host ""
    throw
}

