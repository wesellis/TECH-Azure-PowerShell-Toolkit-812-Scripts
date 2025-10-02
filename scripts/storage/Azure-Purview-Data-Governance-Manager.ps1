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
    [string]$PurviewAccountName,
    [Parameter()]
    [string]$Location = "East US",
    [Parameter()]
    [ValidateSet("Create", "Delete", "GetInfo", "RegisterDataSource", "CreateCollection", "ScanDataSource", "ManageClassifications")]
    [string]$Action = "Create",
    [Parameter()]
    [string]$ManagedStorageAccountName,
    [Parameter()]
    [string]$ManagedEventHubNamespace,
    [Parameter()]
    [string]$DataSourceName,
    [Parameter()]
    [ValidateSet("AzureBlob", "AzureDataLakeGen2", "AzureSqlDatabase", "AzureSynapseAnalytics", "PowerBI")]
    [string]$DataSourceType = "AzureBlob",
    [Parameter()]
    [string]$DataSourceEndpoint,
    [Parameter()]
    [string]$CollectionName = "Default",
    [Parameter()]
    [string]$ScanName,
    [Parameter()]
    [string]$ScanRulesetName = "AdlsGen2",
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
try {
        if (-not (Get-AzContext)) { throw "Not connected to Azure" }

        Install-Module Az.Purview -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Purview
    }
        $ResourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

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
                $PurviewParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $PurviewAccountName
                Location = $Location
                ManagedResourceGroupName = "$ResourceGroupName-purview-managed"
                PublicNetworkAccess = if ($NetworkRules.Count -gt 0) { "Disabled" } else { "Enabled" }
                ManagedEventHubState = "Enabled"
            }
            if ($EnableManagedVNet) {
                $PurviewParams.ManagedVirtualNetwork = "Enabled"
            }
            $PurviewAccount = Invoke-AzureOperation -Operation {
                New-AzPurviewAccount -ErrorAction Stop @purviewParams
            } -OperationName "Create Purview Account"


            do {
                Start-Sleep -Seconds 30
                $AccountStatus = Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName

            } while ($AccountStatus.ProvisioningState -eq "Provisioning")
            if ($AccountStatus.ProvisioningState -eq "Succeeded") {

            } else {
                throw "Purview account provisioning failed with state: $($AccountStatus.ProvisioningState)"
            }
        }
        "registerdatasource" {
            if (-not $DataSourceName -or -not $DataSourceEndpoint) {
                throw "DataSourceName and DataSourceEndpoint are required for data source registration"
            }
            $PurviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
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
                $uri = "$($PurviewAccount.ScanEndpoint)/datasources/$DataSourceName" + "?api-version=2022-02-01-preview"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Register Data Source"

        }
        "createcollection" {
            $PurviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
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
                $uri = "$($PurviewAccount.CatalogEndpoint)/api/collections/$CollectionName" + "?api-version=2022-03-01-preview"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Create Collection"

        }
        "scandatasource" {
            if (-not $DataSourceName -or -not $ScanName) {
                throw "DataSourceName and ScanName are required for scanning"
            }
            $PurviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
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
                $uri = "$($PurviewAccount.ScanEndpoint)/datasources/$DataSourceName/scans/$ScanName" + "?api-version=2022-02-01-preview"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Create Scan"
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $RunId = [System.Guid]::NewGuid().ToString()
                $uri = "$($PurviewAccount.ScanEndpoint)/datasources/$DataSourceName/scans/$ScanName/runs/$RunId" + "?api-version=2022-02-01-preview"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers
            } -OperationName "Trigger Scan"

        }
        "manageclassifications" {
            $PurviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = "$($PurviewAccount.CatalogEndpoint)/api/v2/types/classificationdef" + "?api-version=2022-03-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response
            } -OperationName "Get Classifications"
            Write-Output ""
            $SystemClassifications = @(
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
            Write-Output "Built-in Classifications:"
            foreach ($classification in $SystemClassifications) {
                Write-Output " $classification"
            }
            if ($ClassificationRules.Count -gt 0) {

                foreach ($rule in $ClassificationRules) {

                }
            }
        }
        "getinfo" {
            $PurviewAccount = Invoke-AzureOperation -Operation {
                Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
            } -OperationName "Get Purview Account"
            $collections = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = "$($PurviewAccount.CatalogEndpoint)/api/collections" + "?api-version=2022-03-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Collections"
            $DataSources = Invoke-AzureOperation -Operation {
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = "$($PurviewAccount.ScanEndpoint)/datasources" + "?api-version=2022-02-01-preview"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Data Sources"
            Write-Output ""
            Write-Output "Purview Account Information"
            Write-Output "Account Name: $($PurviewAccount.Name)"
            Write-Output "Location: $($PurviewAccount.Location)"
            Write-Output "Atlas Endpoint: $($PurviewAccount.AtlasEndpoint)"
            Write-Output "Scan Endpoint: $($PurviewAccount.ScanEndpoint)"
            Write-Output "Catalog Endpoint: $($PurviewAccount.CatalogEndpoint)"
            Write-Output "Provisioning State: $($PurviewAccount.ProvisioningState)"
            Write-Output "Public Network Access: $($PurviewAccount.PublicNetworkAccess)"
            if ($collections.Count -gt 0) {
                Write-Output ""
                Write-Output "[FOLDER] Collections ($($collections.Count)):"
                foreach ($collection in $collections) {
                    Write-Output " $($collection.name)"
                    if ($collection.description) {
                        Write-Output "Description: $($collection.description)"
                    }
                }
            }
            if ($DataSources.Count -gt 0) {
                Write-Output ""
                Write-Output "Data Sources ($($DataSources.Count)):"
                foreach ($source in $DataSources) {
                    Write-Output " $($source.name) ($($source.kind))"
                    if ($source.properties.endpoint) {
                        Write-Output "Endpoint: $($source.properties.endpoint)"
                    }
                }
            }
        }
        "delete" {
                $confirmation = Read-Host "Are you sure you want to delete the Purview account '$PurviewAccountName' and all its data? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {

                return
            }
            Invoke-AzureOperation -Operation {
                if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
            } -OperationName "Delete Purview Account"

        }
    }
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
            $DiagnosticSettings = Invoke-AzureOperation -Operation {
            $LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($LogAnalyticsWorkspace) {
                $ResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Purview/accounts/$PurviewAccountName"
                $DiagnosticParams = @{
                    ResourceId = $ResourceId
                    Name = "$PurviewAccountName-diagnostics"
                    WorkspaceId = $LogAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("ScanStatusLogEvent", "DataSensitivityLogEvent")
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
        $GovernanceRecommendations = @(
        "Establish data stewardship roles and responsibilities",
        "Define data classification and sensitivity policies",
        "Implement automated scanning schedules for data sources",
        "Set up lineage tracking for critical data pipelines",
        "Configure glossary terms for business context",
        "Establish data quality rules and monitoring",
        "Create custom classifications for organization-specific data types",
        "Implement access policies based on data sensitivity"
    )
        $SecurityScore = 0
    $MaxScore = 5
    $SecurityFindings = @()
    if ($Action.ToLower() -eq "create") {
        if ($EnableManagedVNet) {
            $SecurityScore++
            $SecurityFindings += "[OK] Managed virtual network enabled"
        } else {
            $SecurityFindings += "[WARN]  Managed VNet not enabled - consider for enhanced security"
        }
        if ($NetworkRules.Count -gt 0) {
            $SecurityScore++
            $SecurityFindings += "[OK] Network access restrictions configured"
        } else {
            $SecurityFindings += "[WARN]  Public network access enabled - consider restricting"
        }
        if ($EnableMonitoring) {
            $SecurityScore++
            $SecurityFindings += "[OK] Monitoring and logging enabled"
        } else {
            $SecurityFindings += "[WARN]  Monitoring not configured"
        }
        if ($EnableDataDiscovery) {
            $SecurityScore++
            $SecurityFindings += "[OK] Automated data discovery enabled"
        } else {
            $SecurityFindings += "[WARN]  Automated data discovery not enabled"
        }
        if ($EnableLineageTracking) {
            $SecurityScore++
            $SecurityFindings += "[OK] Data lineage tracking enabled"
        } else {
            $SecurityFindings += "[WARN]  Data lineage tracking not enabled"
        }
    }
        $ComplianceFrameworks = @(
        "GDPR - General Data Protection Regulation",
        "CCPA - California Consumer Privacy Act",
        "SOX - Sarbanes-Oxley Act",
        "HIPAA - Health Insurance Portability and Accountability Act",
        "PCI DSS - Payment Card Industry Data Security Standard",
        "ISO 27001 - Information Security Management",
        "NIST - National Institute of Standards and Technology Framework"
    )
        $CostComponents = @{
        "Purview Account" = "~$1,212/month base cost"
        "Managed Storage" = "~$25-50/month depending on metadata volume"
        "Managed Event Hub" = "~$100-200/month for event processing"
        "Data Scanning" = "Per scan execution (~$1-5 per scan)"
        "API Calls" = "First 1M calls/month free, then $0.50/1M calls"
        "Data Map Storage" = "First 10GB free, then $0.05/GB/month"
    }
        if ($Action.ToLower() -ne "delete") {
        $AccountStatus = Invoke-AzureOperation -Operation {
            Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName
        } -OperationName "Validate Account Status"
    }
    Write-Output ""
    Write-Output "                      AZURE PURVIEW DATA GOVERNANCE READY"
    Write-Output ""
    if ($Action.ToLower() -eq "create") {
        Write-Output "Purview Account Details:"
        Write-Output "    Account Name: $PurviewAccountName"
        Write-Output "    Resource Group: $ResourceGroupName"
        Write-Output "    Location: $Location"
        Write-Output "    Atlas Endpoint: $($AccountStatus.AtlasEndpoint)"
        Write-Output "    Scan Endpoint: $($AccountStatus.ScanEndpoint)"
        Write-Output "    Catalog Endpoint: $($AccountStatus.CatalogEndpoint)"
        Write-Output "    Status: $($AccountStatus.ProvisioningState)"
        Write-Output ""
        Write-Output "[LOCK] Security Assessment: $SecurityScore/$MaxScore"
        foreach ($finding in $SecurityFindings) {
            Write-Output "   $finding"
        }
        Write-Output ""
        Write-Output "Cost Components:"
        foreach ($cost in $CostComponents.GetEnumerator()) {
            Write-Output "    $($cost.Key): $($cost.Value)"
        }
    }
    Write-Output ""
    foreach ($recommendation in $GovernanceRecommendations) {
        Write-Output "   $recommendation"
    }
    Write-Output ""
    Write-Output "Supported Compliance Frameworks:"
    foreach ($framework in $ComplianceFrameworks) {
        Write-Output "    $framework"
    }
    Write-Output ""
    Write-Output "    Register your data sources using RegisterDataSource action"
    Write-Output "    Create collections to organize your data assets"
    Write-Output "    Set up automated scanning schedules"
    Write-Output "    Configure data classifications and sensitivity labels"
    Write-Output "    Establish data lineage for critical data flows"
    Write-Output "    Train data stewards on Purview Studio usage"
    Write-Output ""

} catch {

    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify Purview service availability in your region"
    Write-Output "    Check subscription quotas and resource limits"
    Write-Output "    Ensure proper permissions for data governance operations"
    Write-Output "    Validate data source connectivity and permissions"
    Write-Output "    Check network connectivity to Purview endpoints"
    Write-Output ""
    throw`n}
