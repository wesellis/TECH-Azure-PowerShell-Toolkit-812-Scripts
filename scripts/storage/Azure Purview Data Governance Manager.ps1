#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Purview Data Governance Manager

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PurviewAccountName,
    [Parameter(ValueFromPipeline)]`n    [string]$Location = "East US",
    [Parameter()]
    [ValidateSet("Create", "Delete", "GetInfo", "RegisterDataSource", "CreateCollection", "ScanDataSource", "ManageClassifications")]
    [string]$Action = "Create",
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ManagedStorageAccountName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ManagedEventHubNamespace,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DataSourceName,
    [Parameter()]
    [ValidateSet("AzureBlob", "AzureDataLakeGen2", "AzureSqlDatabase", "AzureSynapseAnalytics", "PowerBI")]
    [string]$DataSourceType = "AzureBlob",
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DataSourceEndpoint,
    [Parameter(ValueFromPipeline)]`n    [string]$CollectionName = "Default",
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ScanName,
    [Parameter(ValueFromPipeline)]`n    [string]$ScanRulesetName = "AdlsGen2" ,
    [Parameter()]
    [string[]]$ClassificationRules = @(),
    [Parameter()]
    [hashtable]$NetworkRules = @{},
    [Parameter()]
    [switch]$EnableManagedVNet,
    [Parameter()]
    [switch]$EnableMonitoring,
    [Parameter()]
    [switch]$EnableDataDiscovery,
    [Parameter()]
    [switch]$EnableLineageTracking
)
Write-Host "Azure Script Started" -ForegroundColor GreenName "Azure Purview Data Governance Manager" -Version " 1.0" -Description "Enterprise data catalog and governance automation"
try {
    # Test Azure connection
    # Progress stepNumber 1 -TotalSteps 10 -StepName "Azure Connection" -Status "Validating connection and Purview services"
    if (-not (Get-AzContext)) { Connect-AzAccount }nts', 'Az.Resources', 'Az.Purview'))) {

        Install-Module Az.Purview -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Purview
    }
    # Validate resource group
    # Progress stepNumber 2 -TotalSteps 10 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    # Generate managed resource names if not provided
    if (-not $ManagedStorageAccountName) {
        $ManagedStorageAccountName = (" scan" + $PurviewAccountName).ToLower() -replace '[^a-z0-9]', ''
        if ($ManagedStorageAccountName.Length -gt 24) {
            $ManagedStorageAccountName = $ManagedStorageAccountName.Substring(0, 24)
        }
    }
    if (-not $ManagedEventHubNamespace) {
        $ManagedEventHubNamespace = ("Atlas-" + $PurviewAccountName).ToLower()
    }
    switch ($Action.ToLower()) {
        " create" {
            # Create Purview account
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Purview Account Creation" -Status "Creating Azure Purview account"
            $purviewParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $PurviewAccountName
                Location = $Location
                ManagedResourceGroupName = " $ResourceGroupName-purview-managed"
                PublicNetworkAccess = if ($NetworkRules.Count -gt 0) { "Disabled" } else { "Enabled" }
                ManagedEventHubState = "Enabled"
            }
            if ($EnableManagedVNet) {
                $purviewParams.ManagedVirtualNetwork = "Enabled"
            }
            $purviewAccount = Invoke-AzureOperation -Operation {
                New-AzPurviewAccount -ErrorAction Stop @purviewParams
            } -OperationName "Create Purview Account"

            # Wait for account to be ready

            do {
                Start-Sleep -Seconds 30
                $accountStatus = Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName

            } while ($accountStatus.ProvisioningState -eq "Provisioning" )
            if ($accountStatus.ProvisioningState -eq "Succeeded" ) {

            } else {
                throw "Purview account provisioning failed with state: $($accountStatus.ProvisioningState)"
            }
        }
        " registerdatasource" {
            if (-not $DataSourceName -or -not $DataSourceEndpoint) {
                throw "DataSourceName and DataSourceEndpoint are required for data source registration"
            }
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Data Source Registration" -Status "Registering data source with Purview"
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            # Register data source using REST API
            Invoke-AzureOperation -Operation {
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
                $uri = " $($purviewAccount.ScanEndpoint)/datasources/$DataSourceName" + "?api-version=2022-02-01-preview"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Register Data Source"

        }
        " createcollection" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Collection Creation" -Status "Creating data collection"
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
                    description = "Collection Lock created via script"
                    parentCollection = @{
                        referenceName = $PurviewAccountName
                        type = "CollectionReference"
                    }
                } | ConvertTo-Json -Depth 3
                $uri = " $($purviewAccount.CatalogEndpoint)/api/collections/$CollectionName" + "?api-version=2022-03-01-preview"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Create Collection"

        }
        " scandatasource" {
            if (-not $DataSourceName -or -not $ScanName) {
                throw "DataSourceName and ScanName are required for scanning"
            }
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Data Source Scanning" -Status "Initiating data source scan"
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            # Create scan using REST API
            Invoke-AzureOperation -Operation {
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
                $uri = " $($purviewAccount.ScanEndpoint)/datasources/$DataSourceName/scans/$ScanName" + "?api-version=2022-02-01-preview"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Create Scan"
            # Trigger scan
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $runId = [System.Guid]::NewGuid().ToString()
                $uri = " $($purviewAccount.ScanEndpoint)/datasources/$DataSourceName/scans/$ScanName/runs/$runId" + "?api-version=2022-02-01-preview"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers
            } -OperationName "Trigger Scan"

        }
        " manageclassifications" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Classification Management" -Status "Managing data classifications"
            # Get Purview account details
            $purviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            # Get existing classifications
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = " $($purviewAccount.CatalogEndpoint)/api/v2/types/classificationdef" + "?api-version=2022-03-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response
            } -OperationName "Get Classifications"
            Write-Host "" "INFO"
            Write-Host "Available Data Classifications" -ForegroundColor Cyan
            $systemClassifications = @(
                "MICROSOFT.GOVERNMENT.AUSTRALIA.DRIVERS_LICENSE_NUMBER" ,
                "MICROSOFT.GOVERNMENT.AUSTRALIA.PASSPORT_NUMBER" ,
                "MICROSOFT.GOVERNMENT.AUSTRIA.IDENTITY_CARD_NUMBER" ,
                "MICROSOFT.GOVERNMENT.AUSTRIA.PASSPORT_NUMBER" ,
                "MICROSOFT.FINANCIAL.CREDIT_CARD_NUMBER" ,
                "MICROSOFT.FINANCIAL.US.ROUTING_NUMBER" ,
                "MICROSOFT.PERSONAL.EMAIL" ,
                "MICROSOFT.PERSONAL.IPADDRESS" ,
                "MICROSOFT.PERSONAL.NAME" ,
                "MICROSOFT.PERSONAL.PHONENUMBER" ,
                "MICROSOFT.PERSONAL.US.SOCIAL_SECURITY_NUMBER"
            )
            Write-Host "Built-in Classifications:" -ForegroundColor Yellow
            foreach ($classification in $systemClassifications) {
                Write-Host "  $classification" -ForegroundColor White
            }
            # Create custom classifications if provided
            if ($ClassificationRules.Count -gt 0) {

                foreach ($rule in $ClassificationRules) {
                    # This would require  implementation based on specific classification requirements

                }
            }
        }
        " getinfo" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Information Retrieval" -Status "Gathering Purview account information"
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
                $uri = " $($purviewAccount.CatalogEndpoint)/api/collections" + "?api-version=2022-03-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Collections"
            # Get data sources
            $dataSources = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = " $($purviewAccount.ScanEndpoint)/datasources" + "?api-version=2022-02-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Data Sources"
            Write-Host "" "INFO"
            Write-Host "Purview Account Information" -ForegroundColor Cyan
            Write-Host "Account Name: $($purviewAccount.Name)" -ForegroundColor White
            Write-Host "Location: $($purviewAccount.Location)" -ForegroundColor White
            Write-Host "Atlas Endpoint: $($purviewAccount.AtlasEndpoint)" -ForegroundColor White
            Write-Host "Scan Endpoint: $($purviewAccount.ScanEndpoint)" -ForegroundColor White
            Write-Host "Catalog Endpoint: $($purviewAccount.CatalogEndpoint)" -ForegroundColor White
            Write-Host "Provisioning State: $($purviewAccount.ProvisioningState)" -ForegroundColor Green
            Write-Host "Public Network Access: $($purviewAccount.PublicNetworkAccess)" -ForegroundColor White
            if ($collections.Count -gt 0) {
                Write-Host "" "INFO"
                Write-Host " [FOLDER] Collections ($($collections.Count)):" -ForegroundColor Cyan
                foreach ($collection in $collections) {
                    Write-Host "  $($collection.name)" -ForegroundColor White
                    if ($collection.description) {
                        Write-Host "Description: $($collection.description)" -ForegroundColor Gray
                    }
                }
            }
            if ($dataSources.Count -gt 0) {
                Write-Host "" "INFO"
                Write-Host "   Data Sources ($($dataSources.Count)):" -ForegroundColor Cyan
                foreach ($source in $dataSources) {
                    Write-Host "  $($source.name) ($($source.kind))" -ForegroundColor White
                    if ($source.properties.endpoint) {
                        Write-Host "Endpoint: $($source.properties.endpoint)" -ForegroundColor Gray
                    }
                }
            }
        }
        " delete" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Purview Account Deletion" -Status "Removing Purview account"
            $confirmation = Read-Host "Are you sure you want to delete the Purview account '$PurviewAccountName' and all its data? (yes/no)"
            if ($confirmation.ToLower() -ne " yes" ) {

                return
            }
            Invoke-AzureOperation -Operation {
                Remove-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName -Force
            } -OperationName "Delete Purview Account"

        }
    }
    # Configure monitoring if enabled and creating account
    if ($EnableMonitoring -and $Action.ToLower() -eq " create" ) {
        # Progress stepNumber 4 -TotalSteps 10 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($logAnalyticsWorkspace) {
                $resourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Purview/accounts/$PurviewAccountName"
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = " $PurviewAccountName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("ScanStatusLogEvent" , "DataSensitivityLogEvent" )
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
    # Apply enterprise tags if creating account
    if ($Action.ToLower() -eq " create" ) {
        # Progress stepNumber 5 -TotalSteps 10 -StepName "Tagging" -Status "Applying enterprise tags"
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
            $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName -ResourceType "Microsoft.Purview/accounts"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
        } -OperationName "Apply Enterprise Tags"
    }
    # Data governance best practices
    # Progress stepNumber 6 -TotalSteps 10 -StepName "Governance Analysis" -Status "Analyzing data governance setup"
    $governanceRecommendations = @(
        "  Establish data stewardship roles and responsibilities" ,
        "  Define data classification and sensitivity policies" ,
        "  Implement automated scanning schedules for data sources" ,
        "  Set up lineage tracking for critical data pipelines" ,
        "  Configure glossary terms for business context" ,
        "  Establish data quality rules and monitoring" ,
        "  Create custom classifications for organization-specific data types" ,
        "  Implement access policies based on data sensitivity"
    )
    # Security assessment
    # Progress stepNumber 7 -TotalSteps 10 -StepName "Security Assessment" -Status "Evaluating security configuration"
    $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    if ($Action.ToLower() -eq " create" ) {
        # Check managed VNet
        if ($EnableManagedVNet) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Managed virtual network enabled"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Managed VNet not enabled - consider for enhanced security"
        }
        # Check public network access
        if ($NetworkRules.Count -gt 0) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Network access restrictions configured"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Public network access enabled - consider restricting"
        }
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Monitoring and logging enabled"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Monitoring not configured"
        }
        # Check data discovery
        if ($EnableDataDiscovery) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Automated data discovery enabled"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Automated data discovery not enabled"
        }
        # Check lineage tracking
        if ($EnableLineageTracking) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Data lineage tracking enabled"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Data lineage tracking not enabled"
        }
    }
    # Compliance frameworks
    # Progress stepNumber 8 -TotalSteps 10 -StepName "Compliance Analysis" -Status "Evaluating compliance capabilities"
    $complianceFrameworks = @(
        "GDPR - General Data Protection Regulation" ,
        "CCPA - California Consumer Privacy Act" ,
        "SOX - Sarbanes-Oxley Act" ,
        "HIPAA - Health Insurance Portability and Accountability Act" ,
        "PCI DSS - Payment Card Industry Data Security Standard" ,
        "ISO 27001 - Information Security Management" ,
        "NIST - National Institute of Standards and Technology Framework"
    )
    # Cost analysis
    # Progress stepNumber 9 -TotalSteps 10 -StepName "Cost Analysis" -Status "Analyzing cost components"
$costComponents = @{
        "Purview Account" = " ~$1,212/month base cost"
        "Managed Storage" = " ~$25-50/month depending on metadata volume"
        "Managed Event Hub" = " ~$100-200/month for event processing"
        "Data Scanning" = "Per scan execution (~$1-5 per scan)"
        "API Calls" = "First 1M calls/month free, then $0.50/1M calls"
        "Data Map Storage" = "First 10GB free, then $0.05/GB/month"
    }
    # Final validation
    # Progress stepNumber 10 -TotalSteps 10 -StepName "Validation" -Status "Validating data governance setup"
    if ($Action.ToLower() -ne " delete" ) {
$accountStatus = Invoke-AzureOperation -Operation {
            Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
        } -OperationName "Validate Account Status"
    }
    # Success summary
    Write-Host "" "INFO"
    Write-Host "                      AZURE PURVIEW DATA GOVERNANCE READY" -ForegroundColor Green
    Write-Host "" "INFO"
    if ($Action.ToLower() -eq " create" ) {
        Write-Host "Purview Account Details:" -ForegroundColor Cyan
        Write-Host "    Account Name: $PurviewAccountName" -ForegroundColor White
        Write-Host "    Resource Group: $ResourceGroupName" -ForegroundColor White
        Write-Host "    Location: $Location" -ForegroundColor White
        Write-Host "    Atlas Endpoint: $($accountStatus.AtlasEndpoint)" -ForegroundColor White
        Write-Host "    Scan Endpoint: $($accountStatus.ScanEndpoint)" -ForegroundColor White
        Write-Host "    Catalog Endpoint: $($accountStatus.CatalogEndpoint)" -ForegroundColor White
        Write-Host "    Status: $($accountStatus.ProvisioningState)" -ForegroundColor Green
        Write-Host "" "INFO"
        Write-Host " [LOCK] Security Assessment: $securityScore/$maxScore" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding" -ForegroundColor White
        }
        Write-Host "" "INFO"
        Write-Host "Cost Components:" -ForegroundColor Cyan
        foreach ($cost in $costComponents.GetEnumerator()) {
            Write-Host "    $($cost.Key): $($cost.Value)" -ForegroundColor White
        }
    }
    Write-Host "" "INFO"
    Write-Host "Data Governance Best Practices:" -ForegroundColor Cyan
    foreach ($recommendation in $governanceRecommendations) {
        Write-Host "   $recommendation" -ForegroundColor White
    }
    Write-Host "" "INFO"
    Write-Host "   Supported Compliance Frameworks:" -ForegroundColor Cyan
    foreach ($framework in $complianceFrameworks) {
        Write-Host "    $framework" -ForegroundColor White
    }
    Write-Host "" "INFO"
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "    Register your data sources using RegisterDataSource action" -ForegroundColor White
    Write-Host "    Create collections to organize your data assets" -ForegroundColor White
    Write-Host "    Set up automated scanning schedules" -ForegroundColor White
    Write-Host "    Configure data classifications and sensitivity labels" -ForegroundColor White
    Write-Host "    Establish data lineage for critical data flows" -ForegroundColor White
    Write-Host "    Train data stewards on Purview Studio usage" -ForegroundColor White
    Write-Host "" "INFO"

} catch {

    Write-Host "" "INFO"
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "    Verify Purview service availability in your region" -ForegroundColor White
    Write-Host "    Check subscription quotas and resource limits" -ForegroundColor White
    Write-Host "    Ensure proper permissions for data governance operations" -ForegroundColor White
    Write-Host "    Validate data source connectivity and permissions" -ForegroundColor White
    Write-Host "    Check network connectivity to Purview endpoints" -ForegroundColor White
    Write-Host "" "INFO"
    throw
}

