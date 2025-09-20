<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure AI Document Intelligence Service Manager
#
param(
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
    # Test Azure connection
        if (-not (Get-AzContext)) { Connect-AzAccount }
    # Validate resource group
        $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    switch ($Action.ToLower()) {
        "create" {
            # Create Document Intelligence service
                $serviceParams = @{
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
                    $serviceParams.NetworkRuleSet.IpRules = $NetworkRules.AllowedIPs | ForEach-Object {
                        @{ IpAddress = $_ }
                    }
                }
                if ($NetworkRules.ContainsKey("VNetRules")) {
                    $serviceParams.NetworkRuleSet.VirtualNetworkRules = $NetworkRules.VNetRules
                }
            }
            # Add customer-managed keys if enabled
            if ($EnableCustomerManagedKeys) {
                $serviceParams.Encryption = @{
                    KeyVaultProperties = @{
                        KeyName = "DocumentIntelligenceKey"
                        KeyVersion = ""
                        KeyVaultUri = ""
                    }
                    KeySource = "Microsoft.KeyVault"
                }
            }
            $docIntelligenceService = Invoke-AzureOperation -Operation {
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
            Write-Host ""
            $prebuiltModels = @(
                "prebuilt-document", "prebuilt-layout", "prebuilt-receipt",
                "prebuilt-invoice", "prebuilt-businessCard", "prebuilt-idDocument",
                "prebuilt-tax.us.w2", "prebuilt-tax.us.1098", "prebuilt-tax.us.1099"
            )
            foreach ($model in $prebuiltModels) {
                Write-Host " $model"
            }
        }
        "testservice" {
            if (-not $DocumentUrl) {
                throw "DocumentUrl parameter is required for testing service"
            }
                $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName).Endpoint
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName
            $analysisResult = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Ocp-Apim-Subscription-Key' = $keys.Key1
                    'Content-Type' = 'application/json'
                }
                $body = @{
                    urlSource = $DocumentUrl
                } | ConvertTo-Json
                # Start analysis
                $analyzeUri = "$endpoint/formrecognizer/documentModels/$ModelId`:analyze?api-version=2023-07-31"
                $response = Invoke-RestMethod -Uri $analyzeUri -Method POST -Headers $headers -Body $body
                # Get operation location for polling
                $operationLocation = $response.Headers['Operation-Location']
                # Poll for results
                do {
                    Start-Sleep -Seconds 2
                    $result = Invoke-RestMethod -Uri $operationLocation -Method GET -Headers $headers
                } while ($result.status -eq "running")
                return $result
            } -OperationName "Analyze Document"
            Write-Host ""
            Write-Host "[FILE] Document Analysis Results"
            Write-Host "Status: $($analysisResult.status)"
            Write-Host "Model ID: $ModelId"
            Write-Host "Pages: $($analysisResult.analyzeResult.pages.Count)"
            if ($analysisResult.analyzeResult.keyValuePairs) {
                Write-Host "Key-Value Pairs: $($analysisResult.analyzeResult.keyValuePairs.Count)"
            }
        }
        "getkeys" {
                $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName
            } -OperationName "Get API Keys"
            $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName).Endpoint
            Write-Host ""
            Write-Host "Endpoint: $endpoint"
            Write-Host "Key 1: $($keys.Key1)"
            Write-Host "Key 2: $($keys.Key2)"
            Write-Host ""
            Write-Host "[WARN]  Store these keys securely! Consider using Azure Key Vault."
        }
        "delete" {
                $confirmation = Read-Host "Are you sure you want to delete the Document Intelligence service '$ServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                
                return
            }
            Invoke-AzureOperation -Operation {
                Remove-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -Force
            } -OperationName "Delete Document Intelligence Service"
            
        }
    }
    # Configure monitoring if enabled and creating service
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
            $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($logAnalyticsWorkspace) {
                $resourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$ServiceName"
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = "$ServiceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("Audit", "RequestResponse", "Trace")
                    MetricCategory = @("AllMetrics")
                }
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {
                
                return $null
            }
        } -OperationName "Configure Monitoring"
        if ($diagnosticSettings) {
            
        }
    }
    # Apply enterprise tags if creating service
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
    # Security assessment
        $securityScore = 0
    $maxScore = 6
    $securityFindings = @()
    if ($Action.ToLower() -eq "create") {
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
        # Check customer-managed keys
        if ($EnableCustomerManagedKeys) {
            $securityScore++
            $securityFindings += "[OK] Customer-managed encryption enabled"
        } else {
            $securityFindings += "[WARN]  Using Microsoft-managed keys"
        }
        # Check region compliance
        if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
            $securityScore++
            $securityFindings += "[OK] Deployed in compliant region"
        }
        # Check SKU for production readiness
        if ($SkuName -ne "F0") {
            $securityScore++
            $securityFindings += "[OK] Production-ready SKU selected"
        }
        # Check custom subdomain (required for VNet integration)
        $securityScore++
        $securityFindings += "[OK] Custom subdomain configured"
    }
    # Final validation
        if ($Action.ToLower() -ne "delete") {
        $serviceStatus = Invoke-AzureOperation -Operation {
            Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName
        } -OperationName "Validate Service Status"
    }
    # Success summary
        Write-Host ""
    Write-Host "                    AZURE AI DOCUMENT INTELLIGENCE SERVICE READY"
    Write-Host ""
    if ($Action.ToLower() -eq "create") {
        Write-Host "    Service Name: $ServiceName"
        Write-Host "    Resource Group: $ResourceGroupName"
        Write-Host "    Location: $Location"
        Write-Host "    SKU: $SkuName"
        Write-Host "    Endpoint: $($serviceStatus.Endpoint)"
        Write-Host "    Status: $($serviceStatus.ProvisioningState)"
        Write-Host ""
        Write-Host "[LOCK] Security Assessment: $securityScore/$maxScore"
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding"
        }
        Write-Host ""
        Write-Host "    Test with sample documents using TestService action"
        Write-Host "    Configure custom models for specific document types"
        Write-Host "    Set up cost alerts for API usage monitoring"
        Write-Host "    Integrate with your applications using the endpoint and keys"
    }
    Write-Host ""
    Write-Host "    General documents, invoices, receipts, business cards"
    Write-Host "    Identity documents, tax forms (W-2, 1098, 1099)"
    Write-Host "    Custom models for specific document types"
    Write-Host ""
    
} catch {
    
    Write-Host ""
    Write-Host "Troubleshooting Tips:"
    Write-Host "    Verify Document Intelligence service availability in your region"
    Write-Host "    Check subscription quotas for Cognitive Services"
    Write-Host "    Ensure proper permissions for AI service creation"
    Write-Host "    Validate document URL accessibility for testing"
    Write-Host ""
    throw
}

