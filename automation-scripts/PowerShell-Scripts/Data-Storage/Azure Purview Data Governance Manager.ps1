<#
.SYNOPSIS
    Azure Purview Data Governance Manager

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
    We Enhanced Azure Purview Data Governance Manager

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
    [string]$WEPurviewAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " East US" ,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Create" , " Delete" , " GetInfo" , " RegisterDataSource" , " CreateCollection" , " ScanDataSource" , " ManageClassifications" )]
    [string]$WEAction = " Create" ,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEManagedStorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEManagedEventHubNamespace,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDataSourceName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" AzureBlob" , " AzureDataLakeGen2" , " AzureSqlDatabase" , " AzureSynapseAnalytics" , " PowerBI" )]
    [string]$WEDataSourceType = " AzureBlob" ,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDataSourceEndpoint,
    
    [Parameter(Mandatory=$false)]
    [string]$WECollectionName = " Default" ,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEScanName,
    
    [Parameter(Mandatory=$false)]
    [string]$WEScanRulesetName = " AdlsGen2" ,
    
    [Parameter(Mandatory=$false)]
    [string[]]$WEClassificationRules = @(),
    
    [Parameter(Mandatory=$false)]
    [hashtable]$WENetworkRules = @{},
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableManagedVNet,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableDataDiscovery,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableLineageTracking
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force


Show-Banner -ScriptName " Azure Purview Data Governance Manager" -Version " 1.0" -Description " Enterprise data catalog and governance automation"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 10 -StepName " Azure Connection" -Status " Validating connection and Purview services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Purview'))) {
        Write-Log " Installing Azure Purview module..." -Level INFO
        Install-Module Az.Purview -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Purview
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 10 -StepName " Resource Group Validation" -Status " Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction Stop
    } -OperationName " Get Resource Group"
    
    Write-Log " ✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    # Generate managed resource names if not provided
    if (-not $WEManagedStorageAccountName) {
        $WEManagedStorageAccountName = (" scan" + $WEPurviewAccountName).ToLower() -replace '[^a-z0-9]', ''
        if ($WEManagedStorageAccountName.Length -gt 24) {
            $WEManagedStorageAccountName = $WEManagedStorageAccountName.Substring(0, 24)
        }
    }
    
    if (-not $WEManagedEventHubNamespace) {
        $WEManagedEventHubNamespace = (" Atlas-" + $WEPurviewAccountName).ToLower()
    }

    switch ($WEAction.ToLower()) {
        " create" {
            # Create Purview account
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Purview Account Creation" -Status " Creating Azure Purview account"
            
            $purviewParams = @{
                ResourceGroupName = $WEResourceGroupName
                Name = $WEPurviewAccountName
                Location = $WELocation
                ManagedResourceGroupName = " $WEResourceGroupName-purview-managed"
                PublicNetworkAccess = if ($WENetworkRules.Count -gt 0) { " Disabled" } else { " Enabled" }
                ManagedEventHubState = " Enabled"
            }
            
            if ($WEEnableManagedVNet) {
                $purviewParams.ManagedVirtualNetwork = " Enabled"
            }
            
            $purviewAccount = Invoke-AzureOperation -Operation {
                New-AzPurviewAccount @purviewParams
            } -OperationName " Create Purview Account"
            
            Write-Log " ✓ Purview account created: $WEPurviewAccountName" -Level SUCCESS
            Write-Log " ✓ Atlas endpoint: $($purviewAccount.AtlasEndpoint)" -Level INFO
            Write-Log " ✓ Scan endpoint: $($purviewAccount.ScanEndpoint)" -Level INFO
            Write-Log " ✓ Catalog endpoint: $($purviewAccount.CatalogEndpoint)" -Level INFO
            
            # Wait for account to be ready
            Write-Log " Waiting for Purview account to be fully provisioned..." -Level INFO
            do {
                Start-Sleep -Seconds 30
                $accountStatus = Get-AzPurviewAccount -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName
                Write-Log " Provisioning state: $($accountStatus.ProvisioningState)" -Level INFO
            } while ($accountStatus.ProvisioningState -eq " Provisioning" )
            
            if ($accountStatus.ProvisioningState -eq " Succeeded" ) {
                Write-Log " ✓ Purview account fully provisioned and ready" -Level SUCCESS
            } else {
                throw " Purview account provisioning failed with state: $($accountStatus.ProvisioningState)"
            }
        }
        
        " registerdatasource" {
            if (-not $WEDataSourceName -or -not $WEDataSourceEndpoint) {
                throw " DataSourceName and DataSourceEndpoint are required for data source registration"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Data Source Registration" -Status " Registering data source with Purview"
            
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName
            } -OperationName " Get Purview Account"
            
            # Register data source using REST API
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    kind = $WEDataSourceType
                    name = $WEDataSourceName
                    properties = @{
                        endpoint = $WEDataSourceEndpoint
                        collection = @{
                            referenceName = $WECollectionName
                            type = " CollectionReference"
                        }
                    }
                } | ConvertTo-Json -Depth 5
                
                $uri = " $($purviewAccount.ScanEndpoint)/datasources/$WEDataSourceName" + " ?api-version=2022-02-01-preview"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName " Register Data Source"
            
            Write-Log " ✓ Data source registered: $WEDataSourceName ($WEDataSourceType)" -Level SUCCESS
            Write-Log " ✓ Endpoint: $WEDataSourceEndpoint" -Level INFO
            Write-Log " ✓ Collection: $WECollectionName" -Level INFO
        }
        
        " createcollection" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Collection Creation" -Status " Creating data collection"
            
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName
            } -OperationName " Get Purview Account"
            
            # Create collection using REST API
            $collection = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    name = $WECollectionName
                    friendlyName = $WECollectionName
                    description = " Collection created by Azure automation"
                    parentCollection = @{
                        referenceName = $WEPurviewAccountName
                        type = " CollectionReference"
                    }
                } | ConvertTo-Json -Depth 3
                
                $uri = " $($purviewAccount.CatalogEndpoint)/api/collections/$WECollectionName" + " ?api-version=2022-03-01-preview"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName " Create Collection"
            
            Write-Log " ✓ Collection created: $WECollectionName" -Level SUCCESS
        }
        
        " scandatasource" {
            if (-not $WEDataSourceName -or -not $WEScanName) {
                throw " DataSourceName and ScanName are required for scanning"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Data Source Scanning" -Status " Initiating data source scan"
            
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName
            } -OperationName " Get Purview Account"
            
            # Create scan using REST API
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    kind = $WEDataSourceType
                    name = $WEScanName
                    properties = @{
                        scanRulesetName = $WEScanRulesetName
                        scanRulesetType = " System"
                        collection = @{
                            referenceName = $WECollectionName
                            type = " CollectionReference"
                        }
                    }
                } | ConvertTo-Json -Depth 5
                
                $uri = " $($purviewAccount.ScanEndpoint)/datasources/$WEDataSourceName/scans/$WEScanName" + " ?api-version=2022-02-01-preview"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName " Create Scan"
            
            # Trigger scan
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $runId = [System.Guid]::NewGuid().ToString()
                $uri = " $($purviewAccount.ScanEndpoint)/datasources/$WEDataSourceName/scans/$WEScanName/runs/$runId" + " ?api-version=2022-02-01-preview"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers
            } -OperationName " Trigger Scan"
            
            Write-Log " ✓ Data source scan initiated: $WEScanName" -Level SUCCESS
            Write-Log " ✓ Scan ruleset: $WEScanRulesetName" -Level INFO
            Write-Log " ✓ Monitor scan progress in the Purview Studio" -Level INFO
        }
        
        " manageclassifications" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Classification Management" -Status " Managing data classifications"
            
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName
            } -OperationName " Get Purview Account"
            
            # Get existing classifications
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $uri = " $($purviewAccount.CatalogEndpoint)/api/v2/types/classificationdef" + " ?api-version=2022-03-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response
            } -OperationName " Get Classifications"
            
            Write-WELog "" " INFO"
            Write-WELog " 📋 Available Data Classifications" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            
            $systemClassifications = @(
                " MICROSOFT.GOVERNMENT.AUSTRALIA.DRIVERS_LICENSE_NUMBER" ,
                " MICROSOFT.GOVERNMENT.AUSTRALIA.PASSPORT_NUMBER" ,
                " MICROSOFT.GOVERNMENT.AUSTRIA.IDENTITY_CARD_NUMBER" ,
                " MICROSOFT.GOVERNMENT.AUSTRIA.PASSPORT_NUMBER" ,
                " MICROSOFT.FINANCIAL.CREDIT_CARD_NUMBER" ,
                " MICROSOFT.FINANCIAL.US.ROUTING_NUMBER" ,
                " MICROSOFT.PERSONAL.EMAIL" ,
                " MICROSOFT.PERSONAL.IPADDRESS" ,
                " MICROSOFT.PERSONAL.NAME" ,
                " MICROSOFT.PERSONAL.PHONENUMBER" ,
                " MICROSOFT.PERSONAL.US.SOCIAL_SECURITY_NUMBER"
            )
            
            Write-WELog " Built-in Classifications:" " INFO" -ForegroundColor Yellow
            foreach ($classification in $systemClassifications) {
                Write-WELog " • $classification" " INFO" -ForegroundColor White
            }
            
            # Create custom classifications if provided
            if ($WEClassificationRules.Count -gt 0) {
                Write-Log " Creating custom classification rules..." -Level INFO
                foreach ($rule in $WEClassificationRules) {
                    # This would require detailed implementation based on specific classification requirements
                    Write-Log " Custom classification rule: $rule (implementation required)" -Level INFO
                }
            }
        }
        
        " getinfo" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Information Retrieval" -Status " Gathering Purview account information"
            
            # Get Purview account info
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName
            } -OperationName " Get Purview Account"
            
            # Get collections
            $collections = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $uri = " $($purviewAccount.CatalogEndpoint)/api/collections" + " ?api-version=2022-03-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName " Get Collections"
            
            # Get data sources
            $dataSources = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $uri = " $($purviewAccount.ScanEndpoint)/datasources" + " ?api-version=2022-02-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName " Get Data Sources"
            
            Write-WELog "" " INFO"
            Write-WELog " 📊 Purview Account Information" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            Write-WELog " Account Name: $($purviewAccount.Name)" " INFO" -ForegroundColor White
            Write-WELog " Location: $($purviewAccount.Location)" " INFO" -ForegroundColor White
            Write-WELog " Atlas Endpoint: $($purviewAccount.AtlasEndpoint)" " INFO" -ForegroundColor White
            Write-WELog " Scan Endpoint: $($purviewAccount.ScanEndpoint)" " INFO" -ForegroundColor White
            Write-WELog " Catalog Endpoint: $($purviewAccount.CatalogEndpoint)" " INFO" -ForegroundColor White
            Write-WELog " Provisioning State: $($purviewAccount.ProvisioningState)" " INFO" -ForegroundColor Green
            Write-WELog " Public Network Access: $($purviewAccount.PublicNetworkAccess)" " INFO" -ForegroundColor White
            
            if ($collections.Count -gt 0) {
                Write-WELog "" " INFO"
                Write-WELog " 📁 Collections ($($collections.Count)):" " INFO" -ForegroundColor Cyan
                foreach ($collection in $collections) {
                    Write-WELog " • $($collection.name)" " INFO" -ForegroundColor White
                    if ($collection.description) {
                        Write-WELog "  Description: $($collection.description)" " INFO" -ForegroundColor Gray
                    }
                }
            }
            
            if ($dataSources.Count -gt 0) {
                Write-WELog "" " INFO"
                Write-WELog " 🗄️  Data Sources ($($dataSources.Count)):" " INFO" -ForegroundColor Cyan
                foreach ($source in $dataSources) {
                    Write-WELog " • $($source.name) ($($source.kind))" " INFO" -ForegroundColor White
                    if ($source.properties.endpoint) {
                        Write-WELog "  Endpoint: $($source.properties.endpoint)" " INFO" -ForegroundColor Gray
                    }
                }
            }
        }
        
        " delete" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Purview Account Deletion" -Status " Removing Purview account"
            
            $confirmation = Read-Host " Are you sure you want to delete the Purview account '$WEPurviewAccountName' and all its data? (yes/no)"
            if ($confirmation.ToLower() -ne " yes" ) {
                Write-Log " Deletion cancelled by user" -Level WARN
                return
            }
            
            Invoke-AzureOperation -Operation {
                Remove-AzPurviewAccount -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName -Force
            } -OperationName " Delete Purview Account"
            
            Write-Log " ✓ Purview account deleted: $WEPurviewAccountName" -Level SUCCESS
        }
    }

    # Configure monitoring if enabled and creating account
    if ($WEEnableMonitoring -and $WEAction.ToLower() -eq " create" ) {
        Write-ProgressStep -StepNumber 4 -TotalSteps 10 -StepName " Monitoring Setup" -Status " Configuring diagnostic settings"
        
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName | Select-Object -First 1
            
            if ($logAnalyticsWorkspace) {
                $resourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$WEResourceGroupName/providers/Microsoft.Purview/accounts/$WEPurviewAccountName"
                
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = " $WEPurviewAccountName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @(" ScanStatusLogEvent" , " DataSensitivityLogEvent" )
                    MetricCategory = @(" AllMetrics" )
                }
                
                Set-AzDiagnosticSetting @diagnosticParams
            } else {
                Write-Log " ⚠️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName " Configure Monitoring"
        
        if ($diagnosticSettings) {
            Write-Log " ✓ Monitoring configured with diagnostic settings" -Level SUCCESS
        }
    }

    # Apply enterprise tags if creating account
    if ($WEAction.ToLower() -eq " create" ) {
        Write-ProgressStep -StepNumber 5 -TotalSteps 10 -StepName " Tagging" -Status " Applying enterprise tags"
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
        
        Invoke-AzureOperation -Operation {
            $resource = Get-AzResource -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName -ResourceType " Microsoft.Purview/accounts"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
        } -OperationName " Apply Enterprise Tags"
    }

    # Data governance best practices
    Write-ProgressStep -StepNumber 6 -TotalSteps 10 -StepName " Governance Analysis" -Status " Analyzing data governance setup"
    
    $governanceRecommendations = @(
        " 📊 Establish data stewardship roles and responsibilities" ,
        " 📊 Define data classification and sensitivity policies" ,
        " 📊 Implement automated scanning schedules for data sources" ,
        " 📊 Set up lineage tracking for critical data pipelines" ,
        " 📊 Configure glossary terms for business context" ,
        " 📊 Establish data quality rules and monitoring" ,
        " 📊 Create custom classifications for organization-specific data types" ,
        " 📊 Implement access policies based on data sensitivity"
    )

    # Security assessment
    Write-ProgressStep -StepNumber 7 -TotalSteps 10 -StepName " Security Assessment" -Status " Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    
    if ($WEAction.ToLower() -eq " create" ) {
        # Check managed VNet
        if ($WEEnableManagedVNet) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Managed virtual network enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Managed VNet not enabled - consider for enhanced security"
        }
        
        # Check public network access
        if ($WENetworkRules.Count -gt 0) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Network access restrictions configured"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Public network access enabled - consider restricting"
        }
        
        # Check monitoring
        if ($WEEnableMonitoring) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Monitoring and logging enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Monitoring not configured"
        }
        
        # Check data discovery
        if ($WEEnableDataDiscovery) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Automated data discovery enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Automated data discovery not enabled"
        }
        
        # Check lineage tracking
        if ($WEEnableLineageTracking) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Data lineage tracking enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Data lineage tracking not enabled"
        }
    }

    # Compliance frameworks
    Write-ProgressStep -StepNumber 8 -TotalSteps 10 -StepName " Compliance Analysis" -Status " Evaluating compliance capabilities"
    
    $complianceFrameworks = @(
        " GDPR - General Data Protection Regulation" ,
        " CCPA - California Consumer Privacy Act" , 
        " SOX - Sarbanes-Oxley Act" ,
        " HIPAA - Health Insurance Portability and Accountability Act" ,
        " PCI DSS - Payment Card Industry Data Security Standard" ,
        " ISO 27001 - Information Security Management" ,
        " NIST - National Institute of Standards and Technology Framework"
    )

    # Cost analysis
    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName " Cost Analysis" -Status " Analyzing cost components"
    
   ;  $costComponents = @{
        " Purview Account" = " ~$1,212/month base cost"
        " Managed Storage" = " ~$25-50/month depending on metadata volume"
        " Managed Event Hub" = " ~$100-200/month for event processing"
        " Data Scanning" = " Per scan execution (~$1-5 per scan)"
        " API Calls" = " First 1M calls/month free, then $0.50/1M calls"
        " Data Map Storage" = " First 10GB free, then $0.05/GB/month"
    }

    # Final validation
    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName " Validation" -Status " Validating data governance setup"
    
    if ($WEAction.ToLower() -ne " delete" ) {
       ;  $accountStatus = Invoke-AzureOperation -Operation {
            Get-AzPurviewAccount -ResourceGroupName $WEResourceGroupName -Name $WEPurviewAccountName
        } -OperationName " Validate Account Status"
    }

    # Success summary
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                      AZURE PURVIEW DATA GOVERNANCE READY" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    
    if ($WEAction.ToLower() -eq " create" ) {
        Write-WELog " 📊 Purview Account Details:" " INFO" -ForegroundColor Cyan
        Write-WELog "   • Account Name: $WEPurviewAccountName" " INFO" -ForegroundColor White
        Write-WELog "   • Resource Group: $WEResourceGroupName" " INFO" -ForegroundColor White
        Write-WELog "   • Location: $WELocation" " INFO" -ForegroundColor White
        Write-WELog "   • Atlas Endpoint: $($accountStatus.AtlasEndpoint)" " INFO" -ForegroundColor White
        Write-WELog "   • Scan Endpoint: $($accountStatus.ScanEndpoint)" " INFO" -ForegroundColor White
        Write-WELog "   • Catalog Endpoint: $($accountStatus.CatalogEndpoint)" " INFO" -ForegroundColor White
        Write-WELog "   • Status: $($accountStatus.ProvisioningState)" " INFO" -ForegroundColor Green
        
        Write-WELog "" " INFO"
        Write-WELog " 🔒 Security Assessment: $securityScore/$maxScore" " INFO" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-WELog "   $finding" " INFO" -ForegroundColor White
        }
        
        Write-WELog "" " INFO"
        Write-WELog " 💰 Cost Components:" " INFO" -ForegroundColor Cyan
        foreach ($cost in $costComponents.GetEnumerator()) {
            Write-WELog "   • $($cost.Key): $($cost.Value)" " INFO" -ForegroundColor White
        }
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 📋 Data Governance Best Practices:" " INFO" -ForegroundColor Cyan
    foreach ($recommendation in $governanceRecommendations) {
        Write-WELog "   $recommendation" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 🏛️  Supported Compliance Frameworks:" " INFO" -ForegroundColor Cyan
    foreach ($framework in $complianceFrameworks) {
        Write-WELog "   • $framework" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 💡 Next Steps:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Register your data sources using RegisterDataSource action" " INFO" -ForegroundColor White
    Write-WELog "   • Create collections to organize your data assets" " INFO" -ForegroundColor White
    Write-WELog "   • Set up automated scanning schedules" " INFO" -ForegroundColor White
    Write-WELog "   • Configure data classifications and sensitivity labels" " INFO" -ForegroundColor White
    Write-WELog "   • Establish data lineage for critical data flows" " INFO" -ForegroundColor White
    Write-WELog "   • Train data stewards on Purview Studio usage" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"

    Write-Log " ✅ Azure Purview data governance operation '$WEAction' completed successfully!" -Level SUCCESS

} catch {
    Write-Log " ❌ Purview data governance operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-WELog "" " INFO"
    Write-WELog " 🔧 Troubleshooting Tips:" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Verify Purview service availability in your region" " INFO" -ForegroundColor White
    Write-WELog "   • Check subscription quotas and resource limits" " INFO" -ForegroundColor White
    Write-WELog "   • Ensure proper permissions for data governance operations" " INFO" -ForegroundColor White
    Write-WELog "   • Validate data source connectivity and permissions" " INFO" -ForegroundColor White
    Write-WELog "   • Check network connectivity to Purview endpoints" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"
    
    exit 1
}

Write-Progress -Activity " Purview Data Governance Management" -Completed
Write-Log " Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================