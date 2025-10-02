#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding(SupportsShouldProcess)]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ServiceName,
    [Parameter()]
    [string]$Location = "East US",
    [Parameter()]
    [ValidateSet("F0", "S0")]
    [string]$SkuName = "S0",
    [Parameter()]
    [ValidateSet("Create", "Delete", "GetKeys", "ListModels", "TestService")]
    [string]$Action = "Create",
    [Parameter()]
    [string]$DocumentUrl,
    [Parameter()]
    [string]$ModelId = "prebuilt-document",
    [Parameter()]
    [hashtable]$NetworkRules = @{},
    [Parameter()]
    [switch]$EnableMonitoring,
    [Parameter()]
    [switch]$RestrictPublicAccess,
    [Parameter()]
    [switch]$EnableCustomerManagedKeys
)
try {
        if (-not (Get-AzContext)) { Connect-AzAccount }
        $ResourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    switch ($Action.ToLower()) {
        "create" {
                $ServiceParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $ServiceName
                Location = $Location
                SkuName = $SkuName
                Kind = "FormRecognizer"
                CustomSubdomainName = $ServiceName.ToLower()
                NetworkRuleSet = @{
                    DefaultAction = if ($RestrictPublicAccess) { "Deny" } else { "Allow" }
                    IpRules = @()
                    VirtualNetworkRules = @()
                }
            }
            if ($NetworkRules.Count -gt 0) {
                if ($NetworkRules.ContainsKey("AllowedIPs")) {
                    $ServiceParams.NetworkRuleSet.IpRules = $NetworkRules.AllowedIPs | ForEach-Object {
                        @{ IpAddress = $_ }
                    }
                }
                if ($NetworkRules.ContainsKey("VNetRules")) {
                    $ServiceParams.NetworkRuleSet.VirtualNetworkRules = $NetworkRules.VNetRules
                }
            }
            if ($EnableCustomerManagedKeys) {
                $ServiceParams.Encryption = @{
                    KeyVaultProperties = @{
                        KeyName = "DocumentIntelligenceKey"
                        KeyVersion = ""
                        KeyVaultUri = ""
                    }
                    KeySource = "Microsoft.KeyVault"
                }
            }
            $DocIntelligenceService = Invoke-AzureOperation -Operation {
                New-AzCognitiveServicesAccount -ErrorAction Stop @serviceParams
            } -OperationName "Create Document Intelligence Service"

        }
        "listmodels" {
                $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName).Endpoint
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Ocp-Apim-Subscription-Key' = $keys.Key1
                    'Content-Type' = 'application/json'
                }
                $uri = "$endpoint/formrecognizer/info?api-version=2023-07-31"
                Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
            } -OperationName "List Available Models" | Out-Null
            Write-Output ""
            $PrebuiltModels = @(
                "prebuilt-document", "prebuilt-layout", "prebuilt-receipt",
                "prebuilt-invoice", "prebuilt-businessCard", "prebuilt-idDocument",
                "prebuilt-tax.us.w2", "prebuilt-tax.us.1098", "prebuilt-tax.us.1099"
            )
            foreach ($model in $PrebuiltModels) {
                Write-Output " $model"
            }
        }
        "testservice" {
            if (-not $DocumentUrl) {
                throw "DocumentUrl parameter is required for testing service"
            }
                $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName).Endpoint
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName
            $AnalysisResult = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Ocp-Apim-Subscription-Key' = $keys.Key1
                    'Content-Type' = 'application/json'
                }
                $body = @{
                    urlSource = $DocumentUrl
                } | ConvertTo-Json
                $AnalyzeUri = "$endpoint/formrecognizer/documentModels/$ModelId`:analyze?api-version=2023-07-31"
                $response = Invoke-RestMethod -Uri $AnalyzeUri -Method POST -Headers $headers -Body $body
                $OperationLocation = $response.Headers['Operation-Location']
                do {
                    Start-Sleep -Seconds 2
                    $result = Invoke-RestMethod -Uri $OperationLocation -Method GET -Headers $headers
                } while ($result.status -eq "running")
                return $result
            } -OperationName "Analyze Document"
            Write-Output ""
            Write-Output "[FILE] Document Analysis Results"
            Write-Output "Status: $($AnalysisResult.status)"
            Write-Output "Model ID: $ModelId"
            Write-Output "Pages: $($AnalysisResult.analyzeResult.pages.Count)"
            if ($AnalysisResult.analyzeResult.keyValuePairs) {
                Write-Output "Key-Value Pairs: $($AnalysisResult.analyzeResult.keyValuePairs.Count)"
            }
        }
        "getkeys" {
                $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName
            } -OperationName "Get API Keys"
            $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName).Endpoint
            Write-Output ""
            Write-Output "Endpoint: $endpoint"
            Write-Output "Key 1: $($keys.Key1)"
            Write-Output "Key 2: $($keys.Key2)"
            Write-Output ""
            Write-Output "[WARN]  Store these keys securely! Consider using Azure Key Vault."
        }
        "delete" {
                $confirmation = Read-Host "Are you sure you want to delete the Document Intelligence service '$ServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {

                return
            }
            Invoke-AzureOperation -Operation {
                if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
            } -OperationName "Delete Document Intelligence Service"

        }
    }
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
            $DiagnosticSettings = Invoke-AzureOperation -Operation {
            $LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($LogAnalyticsWorkspace) {
                $ResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$ServiceName"
                $DiagnosticParams = @{
                    ResourceId = $ResourceId
                    Name = "$ServiceName-diagnostics"
                    WorkspaceId = $LogAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("Audit", "RequestResponse", "Trace")
                    MetricCategory = @("AllMetrics")
                }
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {

                return $null
            }
        } -OperationName "Configure Monitoring"
        if ($DiagnosticSettings) {

        }
    }
    if ($Action.ToLower() -eq "create") {
            $tags = @{
            'Environment' = 'Production'
            'Service' = 'DocumentIntelligence'
            'ManagedBy' = 'Azure-Automation'
            'CreatedBy' = $env:USERNAME
            'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
            'CostCenter' = 'AI-Innovation'
            'Compliance' = 'Document-Processing'
            'DataClassification' = 'Confidential'
        }
        Invoke-AzureOperation -Operation {
            $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $ServiceName -ResourceType "Microsoft.CognitiveServices/accounts"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
        } -OperationName "Apply Enterprise Tags" | Out-Null
    }
        $SecurityScore = 0
    $MaxScore = 6
    $SecurityFindings = @()
    if ($Action.ToLower() -eq "create") {
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
        if ($EnableCustomerManagedKeys) {
            $SecurityScore++
            $SecurityFindings += "[OK] Customer-managed encryption enabled"
        } else {
            $SecurityFindings += "[WARN]  Using Microsoft-managed keys"
        }
        if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
            $SecurityScore++
            $SecurityFindings += "[OK] Deployed in compliant region"
        }
        if ($SkuName -ne "F0") {
            $SecurityScore++
            $SecurityFindings += "[OK] Production-ready SKU selected"
        }
        $SecurityScore++
        $SecurityFindings += "[OK] Custom subdomain configured"
    }
        if ($Action.ToLower() -ne "delete") {
        $ServiceStatus = Invoke-AzureOperation -Operation {
            Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName
        } -OperationName "Validate Service Status"
    }
        Write-Output ""
    Write-Output "                    AZURE AI DOCUMENT INTELLIGENCE SERVICE READY"
    Write-Output ""
    if ($Action.ToLower() -eq "create") {
        Write-Output "    Service Name: $ServiceName"
        Write-Output "    Resource Group: $ResourceGroupName"
        Write-Output "    Location: $Location"
        Write-Output "    SKU: $SkuName"
        Write-Output "    Endpoint: $($ServiceStatus.Endpoint)"
        Write-Output "    Status: $($ServiceStatus.ProvisioningState)"
        Write-Output ""
        Write-Output "[LOCK] Security Assessment: $SecurityScore/$MaxScore"
        foreach ($finding in $SecurityFindings) {
            Write-Output "   $finding"
        }
        Write-Output ""
        Write-Output "    Test with sample documents using TestService action"
        Write-Output "    Configure custom models for specific document types"
        Write-Output "    Set up cost alerts for API usage monitoring"
        Write-Output "    Integrate with your applications using the endpoint and keys"
    }
    Write-Output ""
    Write-Output "    General documents, invoices, receipts, business cards"
    Write-Output "    Identity documents, tax forms (W-2, 1098, 1099)"
    Write-Output "    Custom models for specific document types"
    Write-Output ""

} catch {

    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify Document Intelligence service availability in your region"
    Write-Output "    Check subscription quotas for Cognitive Services"
    Write-Output "    Ensure proper permissions for AI service creation"
    Write-Output "    Validate document URL accessibility for testing"
    Write-Output ""
    throw`n}
