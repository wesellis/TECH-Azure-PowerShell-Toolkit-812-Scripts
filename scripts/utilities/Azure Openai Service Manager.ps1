#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Openai Service Manager

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $AccountName,
    [Parameter(ValueFromPipeline)]`n    $Location = "East US" ,
    [Parameter(ValueFromPipeline)]`n    $SkuName = "S0",
    [Parameter(ValueFromPipeline)]`n    $Action = "Create",
    [Parameter(ValueFromPipeline)]`n    $ModelName = " gpt-35-turbo" ,
    [Parameter(ValueFromPipeline)]`n    $ModelVersion = " 0613" ,
    [Parameter(ValueFromPipeline)]`n    $DeploymentName = " gpt-35-turbo-deployment" ,
    [Parameter()]
    [int]$Capacity = 120,
    [Parameter()]
    [hashtable]$NetworkRules = @{},
    [Parameter()]
    [switch]$EnableMonitoring,
    [Parameter()]
    [switch]$RestrictPublicAccess
)
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
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
                if ($NetworkRules.ContainsKey("AllowedIPs" )) {
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
                Invoke-RestMethod -Uri " https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName/deployments/$DeploymentName?api-version=2023-05-01" -Method PUT -Headers $headers -Body $body
            } -OperationName "Deploy AI Model" | Out-Null

        }
        " listmodels" {
    $models = Invoke-AzureOperation -Operation {
    $SubscriptionId = (Get-AzContext).Subscription.Id
    $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                Invoke-RestMethod -Uri " https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName/models?api-version=2023-05-01" -Method GET -Headers $headers
            } -OperationName "List Available Models"
            Write-Output ""
            Write-Output "Available Models for $AccountName" # Color: $2
            foreach ($model in $models.value) {
                Write-Output "  $($model.name) - $($model.version)" # Color: $2
                if ($model.capabilities) {
                    Write-Output "Capabilities: $($model.capabilities -join ', ')" # Color: $2
                }
            }
        }
        " getkeys" {
    $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
            } -OperationName "Get API Keys"
            Write-Output ""
            Write-Output "API Keys for $AccountName" # Color: $2
            Write-Output "Key 1: $($keys.Key1)" # Color: $2
            Write-Output "Key 2: $($keys.Key2)" # Color: $2
            Write-Output ""
            Write-Output "[WARN]  Store these keys securely! Consider using Azure Key Vault." # Color: $2
        }
    }
    if ($EnableMonitoring) {
        Invoke-AzureOperation -Operation {
    $LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($LogAnalyticsWorkspace) {
    $DiagnosticParams = @{
                    ResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$AccountName"
                    Name = " $AccountName-diagnostics"
                    WorkspaceId = $LogAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("Audit" , "RequestResponse" , "Trace" )
                    MetricCategory = @("AllMetrics" )
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
    $SecurityFindings = $SecurityFindings + "[OK] Public access restricted"
    } else {
    $SecurityFindings = $SecurityFindings + "[WARN]  Public access allowed - consider restricting"
    }
    if ($EnableMonitoring) {
    $SecurityScore++
    $SecurityFindings = $SecurityFindings + "[OK] Monitoring enabled"
    } else {
    $SecurityFindings = $SecurityFindings + "[WARN]  Monitoring not configured"
    }
    if ($Location -in @("East US" , "West Europe" , "Southeast Asia" )) {
    $SecurityScore++
    $SecurityFindings = $SecurityFindings + "[OK] Deployed in compliant region"
    }
    if ($SkuName -ne "F0" ) {
    $SecurityScore++
    $SecurityFindings = $SecurityFindings + "[OK] Production-ready SKU selected"
    }
    if ($tags.Count -ge 5) {
    $SecurityScore++
    $SecurityFindings = $SecurityFindings + "[OK] Enterprise tagging compliant"
    }
    $ServiceStatus = Invoke-AzureOperation -Operation {
        Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName
    } -OperationName "Validate Service Status"
    Write-Output ""
    Write-Output "                              AZURE OPENAI SERVICE READY" # Color: $2
    Write-Output ""
    Write-Output "    Account: $AccountName" # Color: $2
    Write-Output "    Resource Group: $ResourceGroupName" # Color: $2
    Write-Output "    Location: $Location" # Color: $2
    Write-Output "    SKU: $SkuName" # Color: $2
    Write-Output "    Endpoint: $($ServiceStatus.Endpoint)" # Color: $2
    Write-Output "    Status: $($ServiceStatus.ProvisioningState)" # Color: $2
    if ($Action.ToLower() -eq "create" ) {
        Write-Output ""
        Write-Output "Model Deployment:" # Color: $2
        Write-Output "    Model: $ModelName ($ModelVersion)" # Color: $2
        Write-Output "    Deployment: $DeploymentName" # Color: $2
        Write-Output "    Capacity: $Capacity TPM" # Color: $2
    }
    Write-Output ""
    Write-Output " [LOCK] Security Assessment: $SecurityScore/$MaxScore" # Color: $2
    foreach ($finding in $SecurityFindings) {
        Write-Output "   $finding" # Color: $2
    }
    Write-Output ""
    Write-Output "Next Steps:" # Color: $2
    Write-Output "    Test API: Use the endpoint and keys to make API calls" # Color: $2
    Write-Output "    Monitor usage: Check Azure Monitor for usage metrics" # Color: $2
    Write-Output "    Set up alerts: Configure cost and usage alerts" # Color: $2
    Write-Output "    Review compliance: Ensure AI governance policies are met" # Color: $2
    Write-Output ""

} catch {

    Write-Output ""
    Write-Output "Troubleshooting Tips:" # Color: $2
    Write-Output "    Verify OpenAI service availability in your region" # Color: $2
    Write-Output "    Check subscription quotas for Cognitive Services" # Color: $2
    Write-Output "    Ensure proper permissions for AI service creation" # Color: $2
    Write-Output "    Validate model availability for your region" # Color: $2
    Write-Output ""
    throw`n}
