<#
.SYNOPSIS
    Azure Documentintelligence Service Manager

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName,
    [Parameter()]
    [string]$Location = "East US" ,
    [Parameter()]
    [ValidateSet("F0" , "S0" )]
    [string]$SkuName = "S0",
    [Parameter()]
    [ValidateSet("Create" , "Delete" , "GetKeys" , "ListModels" , "TestService" )]
    [string]$Action = "Create",
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DocumentUrl,
    [Parameter()]
    [string]$ModelId = " prebuilt-document" ,
    [Parameter()]
    [hashtable]$NetworkRules = @{},
    [Parameter()]
    [switch]$EnableMonitoring,
    [Parameter()]
    [switch]$RestrictPublicAccess,
    [Parameter()]
    [switch]$EnableCustomerManagedKeys
)
Write-Host "Script Started" -ForegroundColor Green
try {
    # Test Azure connection
    # Progress stepNumber 1 -TotalSteps 8 -StepName "Azure Connection" -Status "Validating connection and AI services"
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    # Validate resource group
    # Progress stepNumber 2 -TotalSteps 8 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    switch ($Action.ToLower()) {
        "create" {
            # Create Document Intelligence service
            # Progress stepNumber 3 -TotalSteps 8 -StepName "Service Creation" -Status "Creating Azure AI Document Intelligence service"
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
                if ($NetworkRules.ContainsKey("AllowedIPs" )) {
                    $serviceParams.NetworkRuleSet.IpRules = $NetworkRules.AllowedIPs | ForEach-Object {
                        @{ IpAddress = $_ }
                    }
                }
                if ($NetworkRules.ContainsKey("VNetRules" )) {
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
        " listmodels" {
            # Progress stepNumber 3 -TotalSteps 8 -StepName "Model Discovery" -Status "Retrieving available models"
            $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName).Endpoint
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Ocp-Apim-Subscription-Key' = $keys.Key1
                    'Content-Type' = 'application/json'
                }
                $uri = " $endpoint/formrecognizer/info?api-version=2023-07-31"
                Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
            } -OperationName "List Available Models" | Out-Null
            Write-Host ""
            Write-Host "Available Document Intelligence Models" -ForegroundColor Cyan
            $prebuiltModels = @(
                " prebuilt-document" , "prebuilt-layout" , "prebuilt-receipt" ,
                " prebuilt-invoice" , "prebuilt-businessCard" , "prebuilt-idDocument" ,
                " prebuilt-tax.us.w2" , "prebuilt-tax.us.1098" , "prebuilt-tax.us.1099"
            )
            foreach ($model in $prebuiltModels) {
                Write-Host "  $model" -ForegroundColor White
            }
        }
        " testservice" {
            if (-not $DocumentUrl) {
                throw "DocumentUrl parameter is required for testing service"
            }
            # Progress stepNumber 3 -TotalSteps 8 -StepName "Service Testing" -Status "Testing document analysis"
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
                $analyzeUri = " $endpoint/formrecognizer/documentModels/$ModelId`:analyze?api-version=2023-07-31"
                $response = Invoke-RestMethod -Uri $analyzeUri -Method POST -Headers $headers -Body $body
                # Get operation location for polling
                $operationLocation = $response.Headers['Operation-Location']
                # Poll for results
                do {
                    Start-Sleep -Seconds 2
                    $result = Invoke-RestMethod -Uri $operationLocation -Method GET -Headers $headers
                } while ($result.status -eq " running" )
                return $result
            } -OperationName "Analyze Document"
            Write-Host ""
            Write-Host " [FILE] Document Analysis Results" -ForegroundColor Cyan
            Write-Host "Status: $($analysisResult.status)" -ForegroundColor Green
            Write-Host "Model ID: $ModelId" -ForegroundColor White
            Write-Host "Pages: $($analysisResult.analyzeResult.pages.Count)" -ForegroundColor White
            if ($analysisResult.analyzeResult.keyValuePairs) {
                Write-Host "Key-Value Pairs: $($analysisResult.analyzeResult.keyValuePairs.Count)" -ForegroundColor White
            }
        }
        " getkeys" {
            # Progress stepNumber 3 -TotalSteps 8 -StepName "Key Retrieval" -Status "Retrieving API keys"
            $keys = Invoke-AzureOperation -Operation {
                Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName
            } -OperationName "Get API Keys"
            $endpoint = (Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName).Endpoint
            Write-Host ""
            Write-Host "Document Intelligence Service Details" -ForegroundColor Cyan
            Write-Host "Endpoint: $endpoint" -ForegroundColor White
            Write-Host "Key 1: $($keys.Key1)" -ForegroundColor Yellow
            Write-Host "Key 2: $($keys.Key2)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "[WARN]  Store these keys securely! Consider using Azure Key Vault." -ForegroundColor Red
        }
        "delete" {
            # Progress stepNumber 3 -TotalSteps 8 -StepName "Service Deletion" -Status "Removing Document Intelligence service"
            $confirmation = Read-Host "Are you sure you want to delete the Document Intelligence service '$ServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes" ) {

                return
            }
            Invoke-AzureOperation -Operation {
                Remove-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -Force
            } -OperationName "Delete Document Intelligence Service"

        }
    }
    # Configure monitoring if enabled and creating service
    if ($EnableMonitoring -and $Action.ToLower() -eq "create" ) {
        # Progress stepNumber 4 -TotalSteps 8 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($logAnalyticsWorkspace) {
                $resourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$ServiceName"
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = " $ServiceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("Audit" , "RequestResponse" , "Trace" )
                    MetricCategory = @("AllMetrics" )
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
    if ($Action.ToLower() -eq "create" ) {
        # Progress stepNumber 5 -TotalSteps 8 -StepName "Tagging" -Status "Applying enterprise tags"
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
    # Progress stepNumber 6 -TotalSteps 8 -StepName "Security Assessment" -Status "Evaluating security configuration"
    $securityScore = 0
    $maxScore = 6
    $securityFindings = @()
    if ($Action.ToLower() -eq "create" ) {
        # Check network access
        if ($RestrictPublicAccess) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK] Public access restricted"
        } else {
            $securityFindings = $securityFindings + "[WARN]  Public access allowed - consider restricting"
        }
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK] Monitoring enabled"
        } else {
            $securityFindings = $securityFindings + "[WARN]  Monitoring not configured"
        }
        # Check customer-managed keys
        if ($EnableCustomerManagedKeys) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK] Customer-managed encryption enabled"
        } else {
            $securityFindings = $securityFindings + "[WARN]  Using Microsoft-managed keys"
        }
        # Check region compliance
        if ($Location -in @("East US" , "West Europe" , "Southeast Asia" )) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK] Deployed in compliant region"
        }
        # Check SKU for production readiness
        if ($SkuName -ne "F0" ) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK] Production-ready SKU selected"
        }
        # Check custom subdomain (required for VNet integration)
        $securityScore++
$securityFindings = $securityFindings + "[OK] Custom subdomain configured"
    }
    # Final validation
    # Progress stepNumber 7 -TotalSteps 8 -StepName "Validation" -Status "Verifying service health"
    if ($Action.ToLower() -ne "delete" ) {
$serviceStatus = Invoke-AzureOperation -Operation {
            Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName
        } -OperationName "Validate Service Status"
    }
    # Success summary
    # Progress stepNumber 8 -TotalSteps 8 -StepName "Completion" -Status "Finalizing operation"
    Write-Host ""
    Write-Host "                    AZURE AI DOCUMENT INTELLIGENCE SERVICE READY" -ForegroundColor Green
    Write-Host ""
    if ($Action.ToLower() -eq "create" ) {
        Write-Host "    Service Name: $ServiceName" -ForegroundColor White
        Write-Host "    Resource Group: $ResourceGroupName" -ForegroundColor White
        Write-Host "    Location: $Location" -ForegroundColor White
        Write-Host "    SKU: $SkuName" -ForegroundColor White
        Write-Host "    Endpoint: $($serviceStatus.Endpoint)" -ForegroundColor White
        Write-Host "    Status: $($serviceStatus.ProvisioningState)" -ForegroundColor Green
        Write-Host ""
        Write-Host " [LOCK] Security Assessment: $securityScore/$maxScore" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "    Test with sample documents using TestService action" -ForegroundColor White
        Write-Host "    Configure custom models for specific document types" -ForegroundColor White
        Write-Host "    Set up cost alerts for API usage monitoring" -ForegroundColor White
        Write-Host "    Integrate with your applications using the endpoint and keys" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Supported Document Types:" -ForegroundColor Cyan
    Write-Host "    General documents, invoices, receipts, business cards" -ForegroundColor White
    Write-Host "    Identity documents, tax forms (W-2, 1098, 1099)" -ForegroundColor White
    Write-Host "    Custom models for specific document types" -ForegroundColor White
    Write-Host ""

} catch {

    Write-Host ""
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "    Verify Document Intelligence service availability in your region" -ForegroundColor White
    Write-Host "    Check subscription quotas for Cognitive Services" -ForegroundColor White
    Write-Host "    Ensure proper permissions for AI service creation" -ForegroundColor White
    Write-Host "    Validate document URL accessibility for testing" -ForegroundColor White
    Write-Host ""
    throw
}\n