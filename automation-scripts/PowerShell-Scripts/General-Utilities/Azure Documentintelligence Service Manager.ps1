<#
.SYNOPSIS
    Azure Documentintelligence Service Manager

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
    We Enhanced Azure Documentintelligence Service Manager

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
    [string]$WEServiceName,
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " East US" ,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" F0" , " S0" )]
    [string]$WESkuName = " S0" ,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Create" , " Delete" , " GetKeys" , " ListModels" , " TestService" )]
    [string]$WEAction = " Create" ,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDocumentUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$WEModelId = " prebuilt-document" ,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$WENetworkRules = @{},
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$WERestrictPublicAccess,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableCustomerManagedKeys
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force


Show-Banner -ScriptName " Azure AI Document Intelligence Manager" -Version " 1.0" -Description " Enterprise document AI processing automation"

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
            # Create Document Intelligence service
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Service Creation" -Status " Creating Azure AI Document Intelligence service"
            
            $serviceParams = @{
                ResourceGroupName = $WEResourceGroupName
                Name = $WEServiceName
                Location = $WELocation
                SkuName = $WESkuName
                Kind = " FormRecognizer"
                CustomSubdomainName = $WEServiceName.ToLower()
                NetworkRuleSet = @{
                    DefaultAction = if ($WERestrictPublicAccess) { " Deny" } else { " Allow" }
                    IpRules = @()
                    VirtualNetworkRules = @()
                }
            }
            
            if ($WENetworkRules.Count -gt 0) {
                if ($WENetworkRules.ContainsKey(" AllowedIPs" )) {
                    $serviceParams.NetworkRuleSet.IpRules = $WENetworkRules.AllowedIPs | ForEach-Object {
                        @{ IpAddress = $_ }
                    }
                }
                if ($WENetworkRules.ContainsKey(" VNetRules" )) {
                    $serviceParams.NetworkRuleSet.VirtualNetworkRules = $WENetworkRules.VNetRules
                }
            }
            
            # Add customer-managed keys if enabled
            if ($WEEnableCustomerManagedKeys) {
                $serviceParams.Encryption = @{
                    KeyVaultProperties = @{
                        KeyName = " DocumentIntelligenceKey"
                        KeyVersion = ""
                        KeyVaultUri = ""
                    }
                    KeySource = " Microsoft.KeyVault"
                }
            }
            
            $docIntelligenceService = Invoke-AzureOperation -Operation {
                New-AzCognitiveServicesAccount -ErrorAction Stop @serviceParams
            } -OperationName " Create Document Intelligence Service"
            
            Write-Log " ✓ Document Intelligence service created: $WEServiceName" -Level SUCCESS
            Write-Log " ✓ Endpoint: $($docIntelligenceService.Endpoint)" -Level INFO
        }
        
        " listmodels" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Model Discovery" -Status " Retrieving available models"
            
            $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $WEResourceGroupName -Name $WEServiceName).Endpoint
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEServiceName
            
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Ocp-Apim-Subscription-Key' = $keys.Key1
                    'Content-Type' = 'application/json'
                }
                
                $uri = " $endpoint/formrecognizer/info?api-version=2023-07-31"
                Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
            } -OperationName " List Available Models" | Out-Null
            
            Write-WELog "" " INFO"
            Write-WELog " 📋 Available Document Intelligence Models" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            
            $prebuiltModels = @(
                " prebuilt-document" , " prebuilt-layout" , " prebuilt-receipt" , 
                " prebuilt-invoice" , " prebuilt-businessCard" , " prebuilt-idDocument" ,
                " prebuilt-tax.us.w2" , " prebuilt-tax.us.1098" , " prebuilt-tax.us.1099"
            )
            
            foreach ($model in $prebuiltModels) {
                Write-WELog " • $model" " INFO" -ForegroundColor White
            }
        }
        
        " testservice" {
            if (-not $WEDocumentUrl) {
                throw " DocumentUrl parameter is required for testing service"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Service Testing" -Status " Testing document analysis"
            
            $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $WEResourceGroupName -Name $WEServiceName).Endpoint
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEServiceName
            
            $analysisResult = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Ocp-Apim-Subscription-Key' = $keys.Key1
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    urlSource = $WEDocumentUrl
                } | ConvertTo-Json
                
                # Start analysis
                $analyzeUri = " $endpoint/formrecognizer/documentModels/$WEModelId`:analyze?api-version=2023-07-31"
                $response = Invoke-RestMethod -Uri $analyzeUri -Method POST -Headers $headers -Body $body
                
                # Get operation location for polling
                $operationLocation = $response.Headers['Operation-Location']
                
                # Poll for results
                do {
                    Start-Sleep -Seconds 2
                    $result = Invoke-RestMethod -Uri $operationLocation -Method GET -Headers $headers
                } while ($result.status -eq " running" )
                
                return $result
            } -OperationName " Analyze Document"
            
            Write-WELog "" " INFO"
            Write-WELog " 📄 Document Analysis Results" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            Write-WELog " Status: $($analysisResult.status)" " INFO" -ForegroundColor Green
            Write-WELog " Model ID: $WEModelId" " INFO" -ForegroundColor White
            Write-WELog " Pages: $($analysisResult.analyzeResult.pages.Count)" " INFO" -ForegroundColor White
            
            if ($analysisResult.analyzeResult.keyValuePairs) {
                Write-WELog " Key-Value Pairs: $($analysisResult.analyzeResult.keyValuePairs.Count)" " INFO" -ForegroundColor White
            }
        }
        
        " getkeys" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Key Retrieval" -Status " Retrieving API keys"
            
            $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEServiceName
            } -OperationName " Get API Keys"
            
            $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $WEResourceGroupName -Name $WEServiceName).Endpoint
            
            Write-WELog "" " INFO"
            Write-WELog " 🔑 Document Intelligence Service Details" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            Write-WELog " Endpoint: $endpoint" " INFO" -ForegroundColor White
            Write-WELog " Key 1: $($keys.Key1)" " INFO" -ForegroundColor Yellow
            Write-WELog " Key 2: $($keys.Key2)" " INFO" -ForegroundColor Yellow
            Write-WELog "" " INFO"
            Write-WELog " ⚠️  Store these keys securely! Consider using Azure Key Vault." " INFO" -ForegroundColor Red
        }
        
        " delete" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Service Deletion" -Status " Removing Document Intelligence service"
            
            $confirmation = Read-Host " Are you sure you want to delete the Document Intelligence service '$WEServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne " yes" ) {
                Write-Log " Deletion cancelled by user" -Level WARN
                return
            }
            
            Invoke-AzureOperation -Operation {
                Remove-AzCognitiveServicesAccount -ResourceGroupName $WEResourceGroupName -Name $WEServiceName -Force
            } -OperationName " Delete Document Intelligence Service"
            
            Write-Log " ✓ Document Intelligence service deleted: $WEServiceName" -Level SUCCESS
        }
    }

    # Configure monitoring if enabled and creating service
    if ($WEEnableMonitoring -and $WEAction.ToLower() -eq " create" ) {
        Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName " Monitoring Setup" -Status " Configuring diagnostic settings"
        
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName | Select-Object -First 1
            
            if ($logAnalyticsWorkspace) {
                $resourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$WEResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$WEServiceName"
                
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = " $WEServiceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @(" Audit" , " RequestResponse" , " Trace" )
                    MetricCategory = @(" AllMetrics" )
                }
                
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {
                Write-Log " ⚠️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName " Configure Monitoring"
        
        if ($diagnosticSettings) {
            Write-Log " ✓ Monitoring configured with diagnostic settings" -Level SUCCESS
        }
    }

    # Apply enterprise tags if creating service
    if ($WEAction.ToLower() -eq " create" ) {
        Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName " Tagging" -Status " Applying enterprise tags"
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
            $resource = Get-AzResource -ResourceGroupName $WEResourceGroupName -Name $WEServiceName -ResourceType " Microsoft.CognitiveServices/accounts"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
        } -OperationName " Apply Enterprise Tags" | Out-Null
    }

    # Security assessment
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName " Security Assessment" -Status " Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 6
    $securityFindings = @()
    
    if ($WEAction.ToLower() -eq " create" ) {
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
        
        # Check customer-managed keys
        if ($WEEnableCustomerManagedKeys) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Customer-managed encryption enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Using Microsoft-managed keys"
        }
        
        # Check region compliance
        if ($WELocation -in @(" East US" , " West Europe" , " Southeast Asia" )) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Deployed in compliant region"
        }
        
        # Check SKU for production readiness
        if ($WESkuName -ne " F0" ) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Production-ready SKU selected"
        }
        
        # Check custom subdomain (required for VNet integration)
        $securityScore++
       ;  $securityFindings = $securityFindings + " ✓ Custom subdomain configured"
    }

    # Final validation
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName " Validation" -Status " Verifying service health"
    
    if ($WEAction.ToLower() -ne " delete" ) {
       ;  $serviceStatus = Invoke-AzureOperation -Operation {
            Get-AzCognitiveServicesAccount -ResourceGroupName $WEResourceGroupName -Name $WEServiceName
        } -OperationName " Validate Service Status"
    }

    # Success summary
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName " Completion" -Status " Finalizing operation"
    
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                    AZURE AI DOCUMENT INTELLIGENCE SERVICE READY" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    
    if ($WEAction.ToLower() -eq " create" ) {
        Write-WELog " 🤖 Document Intelligence Service Details:" " INFO" -ForegroundColor Cyan
        Write-WELog "   • Service Name: $WEServiceName" " INFO" -ForegroundColor White
        Write-WELog "   • Resource Group: $WEResourceGroupName" " INFO" -ForegroundColor White
        Write-WELog "   • Location: $WELocation" " INFO" -ForegroundColor White
        Write-WELog "   • SKU: $WESkuName" " INFO" -ForegroundColor White
        Write-WELog "   • Endpoint: $($serviceStatus.Endpoint)" " INFO" -ForegroundColor White
        Write-WELog "   • Status: $($serviceStatus.ProvisioningState)" " INFO" -ForegroundColor Green
        
        Write-WELog "" " INFO"
        Write-WELog " 🔒 Security Assessment: $securityScore/$maxScore" " INFO" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-WELog "   $finding" " INFO" -ForegroundColor White
        }
        
        Write-WELog "" " INFO"
        Write-WELog " 💡 Next Steps:" " INFO" -ForegroundColor Cyan
        Write-WELog "   • Test with sample documents using TestService action" " INFO" -ForegroundColor White
        Write-WELog "   • Configure custom models for specific document types" " INFO" -ForegroundColor White
        Write-WELog "   • Set up cost alerts for API usage monitoring" " INFO" -ForegroundColor White
        Write-WELog "   • Integrate with your applications using the endpoint and keys" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 📚 Supported Document Types:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • General documents, invoices, receipts, business cards" " INFO" -ForegroundColor White
    Write-WELog "   • Identity documents, tax forms (W-2, 1098, 1099)" " INFO" -ForegroundColor White
    Write-WELog "   • Custom models for specific document types" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"

    Write-Log " ✅ Azure AI Document Intelligence service '$WEServiceName' operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log " ❌ Document Intelligence service operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-WELog "" " INFO"
    Write-WELog " 🔧 Troubleshooting Tips:" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Verify Document Intelligence service availability in your region" " INFO" -ForegroundColor White
    Write-WELog "   • Check subscription quotas for Cognitive Services" " INFO" -ForegroundColor White
    Write-WELog "   • Ensure proper permissions for AI service creation" " INFO" -ForegroundColor White
    Write-WELog "   • Validate document URL accessibility for testing" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"
    
    exit 1
}

Write-Progress -Activity " Document Intelligence Service Management" -Completed
Write-Log " Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================