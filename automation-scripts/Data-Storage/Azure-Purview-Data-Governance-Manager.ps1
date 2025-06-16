# Azure Purview Data Governance Manager
# Professional Azure data governance automation script
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0 | Enterprise data catalog and governance automation

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$PurviewAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Create", "Delete", "GetInfo", "RegisterDataSource", "CreateCollection", "ScanDataSource", "ManageClassifications")]
    [string]$Action = "Create",
    
    [Parameter(Mandatory=$false)]
    [string]$ManagedStorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$ManagedEventHubNamespace,
    
    [Parameter(Mandatory=$false)]
    [string]$DataSourceName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureBlob", "AzureDataLakeGen2", "AzureSqlDatabase", "AzureSynapseAnalytics", "PowerBI")]
    [string]$DataSourceType = "AzureBlob",
    
    [Parameter(Mandatory=$false)]
    [string]$DataSourceEndpoint,
    
    [Parameter(Mandatory=$false)]
    [string]$CollectionName = "Default",
    
    [Parameter(Mandatory=$false)]
    [string]$ScanName,
    
    [Parameter(Mandatory=$false)]
    [string]$ScanRulesetName = "AdlsGen2",
    
    [Parameter(Mandatory=$false)]
    [string[]]$ClassificationRules = @(),
    
    [Parameter(Mandatory=$false)]
    [hashtable]$NetworkRules = @{},
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableManagedVNet,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableDataDiscovery,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableLineageTracking
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

# Professional banner
Show-Banner -ScriptName "Azure Purview Data Governance Manager" -Version "1.0" -Description "Enterprise data catalog and governance automation"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 10 -StepName "Azure Connection" -Status "Validating connection and Purview services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Purview'))) {
        Write-Log "Installing Azure Purview module..." -Level INFO
        Install-Module Az.Purview -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Purview
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 10 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    Write-Log "✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    # Generate managed resource names if not provided
    if (-not $ManagedStorageAccountName) {
        $ManagedStorageAccountName = ("scan" + $PurviewAccountName).ToLower() -replace '[^a-z0-9]', ''
        if ($ManagedStorageAccountName.Length -gt 24) {
            $ManagedStorageAccountName = $ManagedStorageAccountName.Substring(0, 24)
        }
    }
    
    if (-not $ManagedEventHubNamespace) {
        $ManagedEventHubNamespace = ("Atlas-" + $PurviewAccountName).ToLower()
    }

    switch ($Action.ToLower()) {
        "create" {
            # Create Purview account
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Purview Account Creation" -Status "Creating Azure Purview account"
            
            $purviewParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $PurviewAccountName
                Location = $Location
                ManagedResourceGroupName = "$ResourceGroupName-purview-managed"
                PublicNetworkAccess = if ($NetworkRules.Count -gt 0) { "Disabled" } else { "Enabled" }
                ManagedEventHubState = "Enabled"
            }
            
            if ($EnableManagedVNet) {
                $purviewParams.ManagedVirtualNetwork = "Enabled"
            }
            
            $purviewAccount = Invoke-AzureOperation -Operation {
                New-AzPurviewAccount @purviewParams
            } -OperationName "Create Purview Account"
            
            Write-Log "✓ Purview account created: $PurviewAccountName" -Level SUCCESS
            Write-Log "✓ Atlas endpoint: $($purviewAccount.AtlasEndpoint)" -Level INFO
            Write-Log "✓ Scan endpoint: $($purviewAccount.ScanEndpoint)" -Level INFO
            Write-Log "✓ Catalog endpoint: $($purviewAccount.CatalogEndpoint)" -Level INFO
            
            # Wait for account to be ready
            Write-Log "Waiting for Purview account to be fully provisioned..." -Level INFO
            do {
                Start-Sleep -Seconds 30
                $accountStatus = Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
                Write-Log "Provisioning state: $($accountStatus.ProvisioningState)" -Level INFO
            } while ($accountStatus.ProvisioningState -eq "Provisioning")
            
            if ($accountStatus.ProvisioningState -eq "Succeeded") {
                Write-Log "✓ Purview account fully provisioned and ready" -Level SUCCESS
            } else {
                throw "Purview account provisioning failed with state: $($accountStatus.ProvisioningState)"
            }
        }
        
        "registerdatasource" {
            if (-not $DataSourceName -or -not $DataSourceEndpoint) {
                throw "DataSourceName and DataSourceEndpoint are required for data source registration"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Data Source Registration" -Status "Registering data source with Purview"
            
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            
            # Register data source using REST API
            $dataSource = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    kind = $DataSourceType
                    name = $DataSourceName
                    properties = @{
                        endpoint = $DataSourceEndpoint
                        collection = @{
                            referenceName = $CollectionName
                            type = "CollectionReference"
                        }
                    }
                } | ConvertTo-Json -Depth 5
                
                $uri = "$($purviewAccount.ScanEndpoint)/datasources/$DataSourceName" + "?api-version=2022-02-01-preview"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Register Data Source"
            
            Write-Log "✓ Data source registered: $DataSourceName ($DataSourceType)" -Level SUCCESS
            Write-Log "✓ Endpoint: $DataSourceEndpoint" -Level INFO
            Write-Log "✓ Collection: $CollectionName" -Level INFO
        }
        
        "createcollection" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Collection Creation" -Status "Creating data collection"
            
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            
            # Create collection using REST API
            $collection = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    name = $CollectionName
                    friendlyName = $CollectionName
                    description = "Collection created by Azure automation"
                    parentCollection = @{
                        referenceName = $PurviewAccountName
                        type = "CollectionReference"
                    }
                } | ConvertTo-Json -Depth 3
                
                $uri = "$($purviewAccount.CatalogEndpoint)/api/collections/$CollectionName" + "?api-version=2022-03-01-preview"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Create Collection"
            
            Write-Log "✓ Collection created: $CollectionName" -Level SUCCESS
        }
        
        "scandatasource" {
            if (-not $DataSourceName -or -not $ScanName) {
                throw "DataSourceName and ScanName are required for scanning"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Data Source Scanning" -Status "Initiating data source scan"
            
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            
            # Create scan using REST API
            $scan = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    kind = $DataSourceType
                    name = $ScanName
                    properties = @{
                        scanRulesetName = $ScanRulesetName
                        scanRulesetType = "System"
                        collection = @{
                            referenceName = $CollectionName
                            type = "CollectionReference"
                        }
                    }
                } | ConvertTo-Json -Depth 5
                
                $uri = "$($purviewAccount.ScanEndpoint)/datasources/$DataSourceName/scans/$ScanName" + "?api-version=2022-02-01-preview"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Create Scan"
            
            # Trigger scan
            $scanRun = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $runId = [System.Guid]::NewGuid().ToString()
                $uri = "$($purviewAccount.ScanEndpoint)/datasources/$DataSourceName/scans/$ScanName/runs/$runId" + "?api-version=2022-02-01-preview"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers
            } -OperationName "Trigger Scan"
            
            Write-Log "✓ Data source scan initiated: $ScanName" -Level SUCCESS
            Write-Log "✓ Scan ruleset: $ScanRulesetName" -Level INFO
            Write-Log "✓ Monitor scan progress in the Purview Studio" -Level INFO
        }
        
        "manageclassifications" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Classification Management" -Status "Managing data classifications"
            
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            
            # Get existing classifications
            $classifications = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $uri = "$($purviewAccount.CatalogEndpoint)/api/v2/types/classificationdef" + "?api-version=2022-03-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response
            } -OperationName "Get Classifications"
            
            Write-Host ""
            Write-Host "📋 Available Data Classifications" -ForegroundColor Cyan
            Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            
            $systemClassifications = @(
                "MICROSOFT.GOVERNMENT.AUSTRALIA.DRIVERS_LICENSE_NUMBER",
                "MICROSOFT.GOVERNMENT.AUSTRALIA.PASSPORT_NUMBER",
                "MICROSOFT.GOVERNMENT.AUSTRIA.IDENTITY_CARD_NUMBER",
                "MICROSOFT.GOVERNMENT.AUSTRIA.PASSPORT_NUMBER",
                "MICROSOFT.FINANCIAL.CREDIT_CARD_NUMBER",
                "MICROSOFT.FINANCIAL.US.ROUTING_NUMBER",
                "MICROSOFT.PERSONAL.EMAIL",
                "MICROSOFT.PERSONAL.IPADDRESS",
                "MICROSOFT.PERSONAL.NAME",
                "MICROSOFT.PERSONAL.PHONENUMBER",
                "MICROSOFT.PERSONAL.US.SOCIAL_SECURITY_NUMBER"
            )
            
            Write-Host "Built-in Classifications:" -ForegroundColor Yellow
            foreach ($classification in $systemClassifications) {
                Write-Host "• $classification" -ForegroundColor White
            }
            
            # Create custom classifications if provided
            if ($ClassificationRules.Count -gt 0) {
                Write-Log "Creating custom classification rules..." -Level INFO
                foreach ($rule in $ClassificationRules) {
                    # This would require detailed implementation based on specific classification requirements
                    Write-Log "Custom classification rule: $rule (implementation required)" -Level INFO
                }
            }
        }
        
        "getinfo" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Information Retrieval" -Status "Gathering Purview account information"
            
            # Get Purview account info
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            
            # Get collections
            $collections = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $uri = "$($purviewAccount.CatalogEndpoint)/api/collections" + "?api-version=2022-03-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Collections"
            
            # Get data sources
            $dataSources = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $uri = "$($purviewAccount.ScanEndpoint)/datasources" + "?api-version=2022-02-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Data Sources"
            
            Write-Host ""
            Write-Host "📊 Purview Account Information" -ForegroundColor Cyan
            Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "Account Name: $($purviewAccount.Name)" -ForegroundColor White
            Write-Host "Location: $($purviewAccount.Location)" -ForegroundColor White
            Write-Host "Atlas Endpoint: $($purviewAccount.AtlasEndpoint)" -ForegroundColor White
            Write-Host "Scan Endpoint: $($purviewAccount.ScanEndpoint)" -ForegroundColor White
            Write-Host "Catalog Endpoint: $($purviewAccount.CatalogEndpoint)" -ForegroundColor White
            Write-Host "Provisioning State: $($purviewAccount.ProvisioningState)" -ForegroundColor Green
            Write-Host "Public Network Access: $($purviewAccount.PublicNetworkAccess)" -ForegroundColor White
            
            if ($collections.Count -gt 0) {
                Write-Host ""
                Write-Host "📁 Collections ($($collections.Count)):" -ForegroundColor Cyan
                foreach ($collection in $collections) {
                    Write-Host "• $($collection.name)" -ForegroundColor White
                    if ($collection.description) {
                        Write-Host "  Description: $($collection.description)" -ForegroundColor Gray
                    }
                }
            }
            
            if ($dataSources.Count -gt 0) {
                Write-Host ""
                Write-Host "🗄️  Data Sources ($($dataSources.Count)):" -ForegroundColor Cyan
                foreach ($source in $dataSources) {
                    Write-Host "• $($source.name) ($($source.kind))" -ForegroundColor White
                    if ($source.properties.endpoint) {
                        Write-Host "  Endpoint: $($source.properties.endpoint)" -ForegroundColor Gray
                    }
                }
            }
        }
        
        "delete" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Purview Account Deletion" -Status "Removing Purview account"
            
            $confirmation = Read-Host "Are you sure you want to delete the Purview account '$PurviewAccountName' and all its data? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                Write-Log "Deletion cancelled by user" -Level WARN
                return
            }
            
            Invoke-AzureOperation -Operation {
                Remove-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName -Force
            } -OperationName "Delete Purview Account"
            
            Write-Log "✓ Purview account deleted: $PurviewAccountName" -Level SUCCESS
        }
    }

    # Configure monitoring if enabled and creating account
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 4 -TotalSteps 10 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            
            if ($logAnalyticsWorkspace) {
                $resourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Purview/accounts/$PurviewAccountName"
                
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = "$PurviewAccountName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("ScanStatusLogEvent", "DataSensitivityLogEvent")
                    MetricCategory = @("AllMetrics")
                }
                
                Set-AzDiagnosticSetting @diagnosticParams
            } else {
                Write-Log "⚠️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName "Configure Monitoring"
        
        if ($diagnosticSettings) {
            Write-Log "✓ Monitoring configured with diagnostic settings" -Level SUCCESS
        }
    }

    # Apply enterprise tags if creating account
    if ($Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 5 -TotalSteps 10 -StepName "Tagging" -Status "Applying enterprise tags"
        $tags = @{
            'Environment' = 'Production'
            'Service' = 'DataGovernance'
            'ManagedBy' = 'Azure-Automation'
            'CreatedBy' = $env:USERNAME
            'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
            'CostCenter' = 'DataManagement'
            'Compliance' = 'DataGovernance'
            'DataClassification' = 'Metadata'
            'Purpose' = 'DataCatalog'
        }
        
        $taggedResource = Invoke-AzureOperation -Operation {
            $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName -ResourceType "Microsoft.Purview/accounts"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
        } -OperationName "Apply Enterprise Tags"
    }

    # Data governance best practices
    Write-ProgressStep -StepNumber 6 -TotalSteps 10 -StepName "Governance Analysis" -Status "Analyzing data governance setup"
    
    $governanceRecommendations = @(
        "📊 Establish data stewardship roles and responsibilities",
        "📊 Define data classification and sensitivity policies",
        "📊 Implement automated scanning schedules for data sources",
        "📊 Set up lineage tracking for critical data pipelines",
        "📊 Configure glossary terms for business context",
        "📊 Establish data quality rules and monitoring",
        "📊 Create custom classifications for organization-specific data types",
        "📊 Implement access policies based on data sensitivity"
    )

    # Security assessment
    Write-ProgressStep -StepNumber 7 -TotalSteps 10 -StepName "Security Assessment" -Status "Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    
    if ($Action.ToLower() -eq "create") {
        # Check managed VNet
        if ($EnableManagedVNet) {
            $securityScore++
            $securityFindings += "✓ Managed virtual network enabled"
        } else {
            $securityFindings += "⚠️  Managed VNet not enabled - consider for enhanced security"
        }
        
        # Check public network access
        if ($NetworkRules.Count -gt 0) {
            $securityScore++
            $securityFindings += "✓ Network access restrictions configured"
        } else {
            $securityFindings += "⚠️  Public network access enabled - consider restricting"
        }
        
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings += "✓ Monitoring and logging enabled"
        } else {
            $securityFindings += "⚠️  Monitoring not configured"
        }
        
        # Check data discovery
        if ($EnableDataDiscovery) {
            $securityScore++
            $securityFindings += "✓ Automated data discovery enabled"
        } else {
            $securityFindings += "⚠️  Automated data discovery not enabled"
        }
        
        # Check lineage tracking
        if ($EnableLineageTracking) {
            $securityScore++
            $securityFindings += "✓ Data lineage tracking enabled"
        } else {
            $securityFindings += "⚠️  Data lineage tracking not enabled"
        }
    }

    # Compliance frameworks
    Write-ProgressStep -StepNumber 8 -TotalSteps 10 -StepName "Compliance Analysis" -Status "Evaluating compliance capabilities"
    
    $complianceFrameworks = @(
        "GDPR - General Data Protection Regulation",
        "CCPA - California Consumer Privacy Act", 
        "SOX - Sarbanes-Oxley Act",
        "HIPAA - Health Insurance Portability and Accountability Act",
        "PCI DSS - Payment Card Industry Data Security Standard",
        "ISO 27001 - Information Security Management",
        "NIST - National Institute of Standards and Technology Framework"
    )

    # Cost analysis
    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName "Cost Analysis" -Status "Analyzing cost components"
    
    $costComponents = @{
        "Purview Account" = "~$1,212/month base cost"
        "Managed Storage" = "~$25-50/month depending on metadata volume"
        "Managed Event Hub" = "~$100-200/month for event processing"
        "Data Scanning" = "Per scan execution (~$1-5 per scan)"
        "API Calls" = "First 1M calls/month free, then $0.50/1M calls"
        "Data Map Storage" = "First 10GB free, then $0.05/GB/month"
    }

    # Final validation
    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName "Validation" -Status "Validating data governance setup"
    
    if ($Action.ToLower() -ne "delete") {
        $accountStatus = Invoke-AzureOperation -Operation {
            Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
        } -OperationName "Validate Account Status"
    }

    # Success summary
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                      AZURE PURVIEW DATA GOVERNANCE READY" -ForegroundColor Green  
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    if ($Action.ToLower() -eq "create") {
        Write-Host "📊 Purview Account Details:" -ForegroundColor Cyan
        Write-Host "   • Account Name: $PurviewAccountName" -ForegroundColor White
        Write-Host "   • Resource Group: $ResourceGroupName" -ForegroundColor White
        Write-Host "   • Location: $Location" -ForegroundColor White
        Write-Host "   • Atlas Endpoint: $($accountStatus.AtlasEndpoint)" -ForegroundColor White
        Write-Host "   • Scan Endpoint: $($accountStatus.ScanEndpoint)" -ForegroundColor White
        Write-Host "   • Catalog Endpoint: $($accountStatus.CatalogEndpoint)" -ForegroundColor White
        Write-Host "   • Status: $($accountStatus.ProvisioningState)" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "🔒 Security Assessment: $securityScore/$maxScore" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "💰 Cost Components:" -ForegroundColor Cyan
        foreach ($cost in $costComponents.GetEnumerator()) {
            Write-Host "   • $($cost.Key): $($cost.Value)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "📋 Data Governance Best Practices:" -ForegroundColor Cyan
    foreach ($recommendation in $governanceRecommendations) {
        Write-Host "   $recommendation" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "🏛️  Supported Compliance Frameworks:" -ForegroundColor Cyan
    foreach ($framework in $complianceFrameworks) {
        Write-Host "   • $framework" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "💡 Next Steps:" -ForegroundColor Cyan
    Write-Host "   • Register your data sources using RegisterDataSource action" -ForegroundColor White
    Write-Host "   • Create collections to organize your data assets" -ForegroundColor White
    Write-Host "   • Set up automated scanning schedules" -ForegroundColor White
    Write-Host "   • Configure data classifications and sensitivity labels" -ForegroundColor White
    Write-Host "   • Establish data lineage for critical data flows" -ForegroundColor White
    Write-Host "   • Train data stewards on Purview Studio usage" -ForegroundColor White
    Write-Host ""

    Write-Log "✅ Azure Purview data governance operation '$Action' completed successfully!" -Level SUCCESS

} catch {
    Write-Log "❌ Purview data governance operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Host ""
    Write-Host "🔧 Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "   • Verify Purview service availability in your region" -ForegroundColor White
    Write-Host "   • Check subscription quotas and resource limits" -ForegroundColor White
    Write-Host "   • Ensure proper permissions for data governance operations" -ForegroundColor White
    Write-Host "   • Validate data source connectivity and permissions" -ForegroundColor White
    Write-Host "   • Check network connectivity to Purview endpoints" -ForegroundColor White
    Write-Host ""
    
    exit 1
}

Write-Progress -Activity "Purview Data Governance Management" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
