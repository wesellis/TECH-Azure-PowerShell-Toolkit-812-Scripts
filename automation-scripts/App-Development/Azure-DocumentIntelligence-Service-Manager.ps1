# Azure AI Document Intelligence Service Manager
# Professional Azure automation script for AI document processing
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0 | Enterprise document AI automation

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("F0", "S0")]
    [string]$SkuName = "S0",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Create", "Delete", "GetKeys", "ListModels", "TestService")]
    [string]$Action = "Create",
    
    [Parameter(Mandatory=$false)]
    [string]$DocumentUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$ModelId = "prebuilt-document",
    
    [Parameter(Mandatory=$false)]
    [hashtable]$NetworkRules = @{},
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$RestrictPublicAccess,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableCustomerManagedKeys
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

# Professional banner
Show-Banner -ScriptName "Azure AI Document Intelligence Manager" -Version "1.0" -Description "Enterprise document AI processing automation"

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
            # Create Document Intelligence service
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Service Creation" -Status "Creating Azure AI Document Intelligence service"
            
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
            
            Write-Log "✓ Document Intelligence service created: $ServiceName" -Level SUCCESS
            Write-Log "✓ Endpoint: $($docIntelligenceService.Endpoint)" -Level INFO
        }
        
        "listmodels" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Model Discovery" -Status "Retrieving available models"
            
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
            
            Write-Information ""
            Write-Information "📋 Available Document Intelligence Models"
            Write-Information "════════════════════════════════════════════════════════════════════"
            
            $prebuiltModels = @(
                "prebuilt-document", "prebuilt-layout", "prebuilt-receipt", 
                "prebuilt-invoice", "prebuilt-businessCard", "prebuilt-idDocument",
                "prebuilt-tax.us.w2", "prebuilt-tax.us.1098", "prebuilt-tax.us.1099"
            )
            
            foreach ($model in $prebuiltModels) {
                Write-Information "• $model"
            }
        }
        
        "testservice" {
            if (-not $DocumentUrl) {
                throw "DocumentUrl parameter is required for testing service"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Service Testing" -Status "Testing document analysis"
            
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
            
            Write-Information ""
            Write-Information "📄 Document Analysis Results"
            Write-Information "════════════════════════════════════════════════════════════════════"
            Write-Information "Status: $($analysisResult.status)"
            Write-Information "Model ID: $ModelId"
            Write-Information "Pages: $($analysisResult.analyzeResult.pages.Count)"
            
            if ($analysisResult.analyzeResult.keyValuePairs) {
                Write-Information "Key-Value Pairs: $($analysisResult.analyzeResult.keyValuePairs.Count)"
            }
        }
        
        "getkeys" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Key Retrieval" -Status "Retrieving API keys"
            
            $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName
            } -OperationName "Get API Keys"
            
            $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName).Endpoint
            
            Write-Information ""
            Write-Information "🔑 Document Intelligence Service Details"
            Write-Information "════════════════════════════════════════════════════════════════════"
            Write-Information "Endpoint: $endpoint"
            Write-Information "Key 1: $($keys.Key1)"
            Write-Information "Key 2: $($keys.Key2)"
            Write-Information ""
            Write-Information "⚠️  Store these keys securely! Consider using Azure Key Vault."
        }
        
        "delete" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Service Deletion" -Status "Removing Document Intelligence service"
            
            $confirmation = Read-Host "Are you sure you want to delete the Document Intelligence service '$ServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                Write-Log "Deletion cancelled by user" -Level WARN
                return
            }
            
            Invoke-AzureOperation -Operation {
                Remove-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -Force
            } -OperationName "Delete Document Intelligence Service"
            
            Write-Log "✓ Document Intelligence service deleted: $ServiceName" -Level SUCCESS
        }
    }

    # Configure monitoring if enabled and creating service
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        
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
                Write-Log "⚠️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName "Configure Monitoring"
        
        if ($diagnosticSettings) {
            Write-Log "✓ Monitoring configured with diagnostic settings" -Level SUCCESS
        }
    }

    # Apply enterprise tags if creating service
    if ($Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName "Tagging" -Status "Applying enterprise tags"
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
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName "Security Assessment" -Status "Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 6
    $securityFindings = @()
    
    if ($Action.ToLower() -eq "create") {
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
        
        # Check customer-managed keys
        if ($EnableCustomerManagedKeys) {
            $securityScore++
            $securityFindings += "✓ Customer-managed encryption enabled"
        } else {
            $securityFindings += "⚠️  Using Microsoft-managed keys"
        }
        
        # Check region compliance
        if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
            $securityScore++
            $securityFindings += "✓ Deployed in compliant region"
        }
        
        # Check SKU for production readiness
        if ($SkuName -ne "F0") {
            $securityScore++
            $securityFindings += "✓ Production-ready SKU selected"
        }
        
        # Check custom subdomain (required for VNet integration)
        $securityScore++
        $securityFindings += "✓ Custom subdomain configured"
    }

    # Final validation
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName "Validation" -Status "Verifying service health"
    
    if ($Action.ToLower() -ne "delete") {
        $serviceStatus = Invoke-AzureOperation -Operation {
            Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName
        } -OperationName "Validate Service Status"
    }

    # Success summary
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName "Completion" -Status "Finalizing operation"
    
    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                    AZURE AI DOCUMENT INTELLIGENCE SERVICE READY"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    
    if ($Action.ToLower() -eq "create") {
        Write-Information "🤖 Document Intelligence Service Details:"
        Write-Information "   • Service Name: $ServiceName"
        Write-Information "   • Resource Group: $ResourceGroupName"
        Write-Information "   • Location: $Location"
        Write-Information "   • SKU: $SkuName"
        Write-Information "   • Endpoint: $($serviceStatus.Endpoint)"
        Write-Information "   • Status: $($serviceStatus.ProvisioningState)"
        
        Write-Information ""
        Write-Information "🔒 Security Assessment: $securityScore/$maxScore"
        foreach ($finding in $securityFindings) {
            Write-Information "   $finding"
        }
        
        Write-Information ""
        Write-Information "💡 Next Steps:"
        Write-Information "   • Test with sample documents using TestService action"
        Write-Information "   • Configure custom models for specific document types"
        Write-Information "   • Set up cost alerts for API usage monitoring"
        Write-Information "   • Integrate with your applications using the endpoint and keys"
    }
    
    Write-Information ""
    Write-Information "📚 Supported Document Types:"
    Write-Information "   • General documents, invoices, receipts, business cards"
    Write-Information "   • Identity documents, tax forms (W-2, 1098, 1099)"
    Write-Information "   • Custom models for specific document types"
    Write-Information ""

    Write-Log "✅ Azure AI Document Intelligence service '$ServiceName' operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log "❌ Document Intelligence service operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Information ""
    Write-Information "🔧 Troubleshooting Tips:"
    Write-Information "   • Verify Document Intelligence service availability in your region"
    Write-Information "   • Check subscription quotas for Cognitive Services"
    Write-Information "   • Ensure proper permissions for AI service creation"
    Write-Information "   • Validate document URL accessibility for testing"
    Write-Information ""
    
    exit 1
}

Write-Progress -Activity "Document Intelligence Service Management" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
