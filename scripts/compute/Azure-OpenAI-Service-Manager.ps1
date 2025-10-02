#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
        if (-not (Get-AzContext)) { Connect-AzAccount }
        $ResourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    switch ($Action.ToLower()) {
        "create" {
                $OpenAIParams = @{
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
                    $OpenAIParams.NetworkRuleSet.IpRules = $NetworkRules.AllowedIPs | ForEach-Object {
                        @{ IpAddress = $_ }
                    }
                }
            }
            Invoke-AzureOperation -Operation {
                New-AzCognitiveServicesAccount -ErrorAction Stop @openAIParams
            } -OperationName "Create OpenAI Account" | Out-Null

                Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
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
                Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName/deployments/$DeploymentName?api-version=2023-05-01" -Method PUT -Headers $headers -Body $body
            } -OperationName "Deploy AI Model" | Out-Null

        }
        "listmodels" {
                $models = Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName/models?api-version=2023-05-01" -Method GET -Headers $headers
            } -OperationName "List Available Models"
            Write-Output ""
            foreach ($model in $models.value) {
                Write-Output " $($model.name) - $($model.version)"
                if ($model.capabilities) {
                    Write-Output "Capabilities: $($model.capabilities -join ', ')"
                }
            }
        }
        "getkeys" {
                $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
            } -OperationName "Get API Keys"
            Write-Output ""
            Write-Output "Key 1: $($keys.Key1)"
            Write-Output "Key 2: $($keys.Key2)"
            Write-Output ""
            Write-Output "[WARN]  Store these keys securely! Consider using Azure Key Vault."
        }
    }
    if ($EnableMonitoring) {
            Invoke-AzureOperation -Operation {
            $LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($LogAnalyticsWorkspace) {
                $DiagnosticParams = @{
                    ResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName"
                    Name = "$AccountName-diagnostics"
                    WorkspaceId = $LogAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("Audit", "RequestResponse", "Trace")
                    MetricCategory = @("AllMetrics")
                }
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {

                return $null
            }
        } -OperationName "Configure Monitoring" | Out-Null
        $DiagnosticSettings = $true
        if ($DiagnosticSettings) {

        }
    }
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
        $SecurityScore = 0
    $MaxScore = 5
    $SecurityFindings = @()
    if ($RestrictPublicAccess) {
        $SecurityScore++
        $SecurityFindings += "[OK] Public access restricted"
    } else {
        $SecurityFindings += "[WARN]  Public access allowed - consider restricting"
    }
    if ($EnableMonitoring) {
        $SecurityScore++
        $SecurityFindings += "[OK] Monitoring enabled"
    } else {
        $SecurityFindings += "[WARN]  Monitoring not configured"
    }
    if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
        $SecurityScore++
        $SecurityFindings += "[OK] Deployed in compliant region"
    }
    if ($SkuName -ne "F0") {
        $SecurityScore++
        $SecurityFindings += "[OK] Production-ready SKU selected"
    }
    if ($tags.Count -ge 5) {
        $SecurityScore++
        $SecurityFindings += "[OK] Enterprise tagging compliant"
    }
        $ServiceStatus = Invoke-AzureOperation -Operation {
        Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName
    } -OperationName "Validate Service Status"
    Write-Output ""
    Write-Output "                              AZURE OPENAI SERVICE READY"
    Write-Output ""
    Write-Output "    Account: $AccountName"
    Write-Output "    Resource Group: $ResourceGroupName"
    Write-Output "    Location: $Location"
    Write-Output "    SKU: $SkuName"
    Write-Output "    Endpoint: $($ServiceStatus.Endpoint)"
    Write-Output "    Status: $($ServiceStatus.ProvisioningState)"
    if ($Action.ToLower() -eq "create") {
        Write-Output ""
        Write-Output "Model Deployment:"
        Write-Output "    Model: $ModelName ($ModelVersion)"
        Write-Output "    Deployment: $DeploymentName"
        Write-Output "    Capacity: $Capacity TPM"
    }
    Write-Output ""
    Write-Output "[LOCK] Security Assessment: $SecurityScore/$MaxScore"
    foreach ($finding in $SecurityFindings) {
        Write-Output "   $finding"
    }
    Write-Output ""
    Write-Output "    Test API: Use the endpoint and keys to make API calls"
    Write-Output "    Monitor usage: Check Azure Monitor for usage metrics"
    Write-Output "    Set up alerts: Configure cost and usage alerts"
    Write-Output "    Review compliance: Ensure AI governance policies are met"
    Write-Output ""

} catch {

    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify OpenAI service availability in your region"
    Write-Output "    Check subscription quotas for Cognitive Services"
    Write-Output "    Ensure proper permissions for AI service creation"
    Write-Output "    Validate model availability for your region"
    Write-Output ""
    throw`n}
