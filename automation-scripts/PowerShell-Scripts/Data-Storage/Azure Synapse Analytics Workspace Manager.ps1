<#
.SYNOPSIS
    Azure Synapse Analytics Workspace Manager

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceName,
    [Parameter()]
    [string]$Location = "East US" ,
    [Parameter()]
    [ValidateSet("Create" , "Delete" , "GetInfo" , "CreateSQLPool" , "CreateSparkPool" , "ManageFirewall" )]
    [string]$Action = "Create" ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    [Parameter()]
    [string]$FileSystemName = " synapsefs" ,
    [Parameter()]
    [string]$SQLAdminUsername = " sqladmin" ,
    [Parameter()]
    [SecureString]$SQLAdminPassword,
    [Parameter()]
    [string]$SQLPoolName = "DataWarehouse" ,
    [Parameter()]
    [ValidateSet("DW100c" , "DW200c" , "DW300c" , "DW400c" , "DW500c" , "DW1000c" )]
    [string]$SQLPoolSKU = "DW100c" ,
    [Parameter()]
    [string]$SparkPoolName = "SparkPool" ,
    [Parameter()]
    [ValidateSet("Small" , "Medium" , "Large" )]
    [string]$SparkPoolSize = "Small" ,
    [Parameter()]
    [int]$SparkPoolMinNodes = 3,
    [Parameter()]
    [int]$SparkPoolMaxNodes = 10,
    [Parameter()]
    [string[]]$AllowedIPs = @(),
    [Parameter()]
    [switch]$EnableManagedVNet,
    [Parameter()]
    [switch]$EnableDataExfiltrationProtection,
    [Parameter()]
    [switch]$EnableMonitoring
)
Write-Host "Azure Script Started" -ForegroundColor GreenName "Azure Synapse Analytics Workspace Manager" -Version " 1.0" -Description "Enterprise data analytics and warehousing automation"
try {
    # Test Azure connection
    # Progress stepNumber 1 -TotalSteps 10 -StepName "Azure Connection" -Status "Validating connection and Synapse services"
    if (-not (Get-AzContext)) { Connect-AzAccount }nts', 'Az.Resources', 'Az.Synapse', 'Az.Storage'))) {
        throw "Azure connection validation failed"
    }
    # Validate resource group
    # Progress stepNumber 2 -TotalSteps 10 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    switch ($Action.ToLower()) {
        " create" {
            # Create or validate storage account for Synapse
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Storage Account" -Status "Setting up primary storage account"
            if (-not $StorageAccountName) {
                $StorageAccountName = ($WorkspaceName + " storage" ).ToLower() -replace '[^a-z0-9]', ''
                if ($StorageAccountName.Length -gt 24) {
                    $StorageAccountName = $StorageAccountName.Substring(0, 24)
                }
            }
            $storageAccount = Invoke-AzureOperation -Operation {
                $existing = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
                if ($existing) {

                    return $existing
                } else {

                    $storageParams = @{
                        ResourceGroupName = $ResourceGroupName
                        Name = $StorageAccountName
                        Location = $Location
                        SkuName = "Standard_LRS"
                        Kind = "StorageV2"
                        EnableHierarchicalNamespace = $true
                        EnableHttpsTrafficOnly = $true
                        MinimumTlsVersion = "TLS1_2"
                    }
                    New-AzStorageAccount -ErrorAction Stop @storageParams
                }
            } -OperationName "Create/Get Storage Account"
            # Create file system
            $ctx = $storageAccount.Context
            $null = Invoke-AzureOperation -Operation {
                $existing = Get-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName -ErrorAction SilentlyContinue
                if (-not $existing) {
                    New-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName

                } else {

                    return $existing
                }
            } -OperationName "Create File System"

            # Generate secure password if not provided
            if (-not $SQLAdminPassword) {
                $passwordText = -join ((65..90) + (97..122) + (48..57) + @(33,35,36,37,38,42,43,45,61,63,64) | Get-Random -Count 16 | ForEach-Object {[char]$_})
                $SQLAdminPassword = ConvertTo-SecureString $passwordText -AsPlainText -Force

            }
            # Create Synapse workspace
            # Progress stepNumber 4 -TotalSteps 10 -StepName "Workspace Creation" -Status "Creating Synapse Analytics workspace"
            $workspaceParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $WorkspaceName
                Location = $Location
                DefaultDataLakeStorageAccountName = $StorageAccountName
                DefaultDataLakeStorageFilesystem = $FileSystemName
                SqlAdministratorLoginCredential = (New-Object -ErrorAction Stop System.Management.Automation.PSCredential($SQLAdminUsername, $SQLAdminPassword))
                ManagedVirtualNetwork = $EnableManagedVNet
                PreventDataExfiltration = $EnableDataExfiltrationProtection
            }
            $workspace = Invoke-AzureOperation -Operation {
                New-AzSynapseWorkspace -ErrorAction Stop @workspaceParams
            } -OperationName "Create Synapse Workspace"

            # Configure firewall rules
            # Progress stepNumber 5 -TotalSteps 10 -StepName "Firewall Configuration" -Status "Setting up firewall rules"
            # Allow Azure services
            Invoke-AzureOperation -Operation {
                New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name "AllowAllWindowsAzureIps" -StartIpAddress " 0.0.0.0" -EndIpAddress " 0.0.0.0"
            } -OperationName "Create Azure Services Firewall Rule"
            # Add custom IP rules
            if ($AllowedIPs.Count -gt 0) {
                foreach ($ip in $AllowedIPs) {
                    $ruleName = "CustomRule-$($ip -replace '\.', '-')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name $ruleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName "Create Custom IP Firewall Rule"
                }

            }
        }
        " createsqlpool" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "SQL Pool Creation" -Status "Creating dedicated SQL pool"
            $sqlPoolParams = @{
                WorkspaceName = $WorkspaceName
                Name = $SQLPoolName
                PerformanceLevel = $SQLPoolSKU
            }
            $null = Invoke-AzureOperation -Operation {
                New-AzSynapseSqlPool -ErrorAction Stop @sqlPoolParams
            } -OperationName "Create SQL Pool"

        }
        " createsparkpool" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Spark Pool Creation" -Status "Creating Apache Spark pool"
            $sparkPoolParams = @{
                WorkspaceName = $WorkspaceName
                Name = $SparkPoolName
                NodeSize = $SparkPoolSize
                NodeCount = $SparkPoolMinNodes
                AutoScaleMinNodeCount = $SparkPoolMinNodes
                AutoScaleMaxNodeCount = $SparkPoolMaxNodes
                AutoScaleEnabled = $true
                AutoPauseEnabled = $true
                AutoPauseDelayInMinute = 15
                SparkVersion = " 3.3"
            }
            $null = Invoke-AzureOperation -Operation {
                New-AzSynapseSparkPool -ErrorAction Stop @sparkPoolParams
            } -OperationName "Create Spark Pool"

        }
        " managefirewall" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Firewall Management" -Status "Managing firewall rules"
            $existingRules = Invoke-AzureOperation -Operation {
                Get-AzSynapseFirewallRule -WorkspaceName $WorkspaceName
            } -OperationName "Get Firewall Rules"
            Write-Host "" "INFO"
            Write-Host "Current Firewall Rules for $WorkspaceName" -ForegroundColor Cyan
            foreach ($rule in $existingRules) {
                Write-Host "  $($rule.Name): $($rule.StartIpAddress) - $($rule.EndIpAddress)" -ForegroundColor White
            }
            # Add new rules if specified
            if ($AllowedIPs.Count -gt 0) {

                foreach ($ip in $AllowedIPs) {
                    $ruleName = "CustomRule-$($ip -replace '\.', '-')-$(Get-Date -Format 'yyyyMMdd')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name $ruleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName "Add Firewall Rule"

                }
            }
        }
        " getinfo" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Information Retrieval" -Status "Gathering workspace information"
            $workspace = Invoke-AzureOperation -Operation {
                Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
            } -OperationName "Get Workspace Info"
            $sqlPools = Invoke-AzureOperation -Operation {
                Get-AzSynapseSqlPool -WorkspaceName $WorkspaceName
            } -OperationName "Get SQL Pools"
            $sparkPools = Invoke-AzureOperation -Operation {
                Get-AzSynapseSparkPool -WorkspaceName $WorkspaceName
            } -OperationName "Get Spark Pools"
            Write-Host "" "INFO"
            Write-Host "Synapse Workspace Information" -ForegroundColor Cyan
            Write-Host "Workspace Name: $($workspace.Name)" -ForegroundColor White
            Write-Host "Location: $($workspace.Location)" -ForegroundColor White
            Write-Host "Workspace URL: $($workspace.WebUrl)" -ForegroundColor White
            Write-Host "SQL Endpoint: $($workspace.SqlAdministratorLogin)" -ForegroundColor White
            Write-Host "Provisioning State: $($workspace.ProvisioningState)" -ForegroundColor Green
            if ($sqlPools.Count -gt 0) {
                Write-Host "" "INFO"
                Write-Host "   SQL Pools:" -ForegroundColor Cyan
                foreach ($pool in $sqlPools) {
                    Write-Host "  $($pool.Name) - $($pool.Sku.Name) - $($pool.Status)" -ForegroundColor White
                }
            }
            if ($sparkPools.Count -gt 0) {
                Write-Host "" "INFO"
                Write-Host " [!] Spark Pools:" -ForegroundColor Cyan
                foreach ($pool in $sparkPools) {
                    Write-Host "  $($pool.Name) - $($pool.NodeSize) - Nodes: $($pool.NodeCount)" -ForegroundColor White
                }
            }
        }
        " delete" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Workspace Deletion" -Status "Removing Synapse workspace"
            $confirmation = Read-Host "Are you sure you want to delete the Synapse workspace '$WorkspaceName' and all its resources? (yes/no)"
            if ($confirmation.ToLower() -ne " yes" ) {

                return
            }
            # Delete SQL pools first
            $sqlPools = Get-AzSynapseSqlPool -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
            foreach ($pool in $sqlPools) {

                Remove-AzSynapseSqlPool -WorkspaceName $WorkspaceName -Name $pool.Name -Force
            }
            # Delete Spark pools
            $sparkPools = Get-AzSynapseSparkPool -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
            foreach ($pool in $sparkPools) {

                Remove-AzSynapseSparkPool -WorkspaceName $WorkspaceName -Name $pool.Name -Force
            }
            # Delete workspace
            Invoke-AzureOperation -Operation {
                Remove-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Force
            } -OperationName "Delete Synapse Workspace"

        }
    }
    # Configure monitoring if enabled and creating workspace
    if ($EnableMonitoring -and $Action.ToLower() -eq " create" ) {
        # Progress stepNumber 6 -TotalSteps 10 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($logAnalyticsWorkspace) {
                $resourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Synapse/workspaces/$WorkspaceName"
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = " $WorkspaceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("SynapseRbacOperations" , "GatewayApiRequests" , "BuiltinSqlReqsEnded" , "IntegrationPipelineRuns" , "IntegrationActivityRuns" , "IntegrationTriggerRuns" )
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
    # Apply enterprise tags if creating workspace
    if ($Action.ToLower() -eq " create" ) {
        # Progress stepNumber 7 -TotalSteps 10 -StepName "Tagging" -Status "Applying enterprise tags"
        $tags = @{
            'Environment' = 'Production'
            'Service' = 'SynapseAnalytics'
            'ManagedBy' = 'Azure-Automation'
            'CreatedBy' = $env:USERNAME
            'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
            'CostCenter' = 'DataAnalytics'
            'Compliance' = 'DataGovernance'
            'DataClassification' = 'Internal'
            'BackupRequired' = 'Yes'
        }
        $null = Invoke-AzureOperation -Operation {
            $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ResourceType "Microsoft.Synapse/workspaces"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force

        } -OperationName "Apply Enterprise Tags"
    }
    # Security assessment
    # Progress stepNumber 8 -TotalSteps 10 -StepName "Security Assessment" -Status "Evaluating security configuration"
    $securityScore = 0
    $maxScore = 6
    $securityFindings = @()
    if ($Action.ToLower() -eq " create" ) {
        # Check managed VNet
        if ($EnableManagedVNet) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Managed virtual network enabled"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Managed VNet not enabled - consider for enhanced security"
        }
        # Check data exfiltration protection
        if ($EnableDataExfiltrationProtection) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Data exfiltration protection enabled"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Data exfiltration protection disabled"
        }
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Monitoring enabled"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Monitoring not configured"
        }
        # Check firewall configuration
        if ($AllowedIPs.Count -gt 0) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Custom firewall rules configured"
        } else {
            $securityFindings = $securityFindings + " [WARN]  Only Azure services allowed - configure specific IP rules"
        }
        # Check storage account security
        if ($storageAccount.EnableHttpsTrafficOnly) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] HTTPS-only traffic enforced on storage"
        }
        # Check region compliance
        if ($Location -in @("East US" , "West Europe" , "Southeast Asia" )) {
            $securityScore++
            $securityFindings = $securityFindings + " [OK] Deployed in compliant region"
        }
    }
    # Cost optimization recommendations
    # Progress stepNumber 9 -TotalSteps 10 -StepName "Cost Analysis" -Status "Analyzing cost optimization opportunities"
    $costRecommendations = @()
    if ($Action.ToLower() -eq " create" ) {
        $costRecommendations = $costRecommendations + "  Enable auto-pause for Spark pools to reduce costs during idle time"
        $costRecommendations = $costRecommendations + "  Use serverless SQL pool for exploratory workloads"
        $costRecommendations = $costRecommendations + "  Schedule SQL pool scaling based on usage patterns"
        $costRecommendations = $costRecommendations + "  Monitor storage costs and implement lifecycle policies"
$costRecommendations = $costRecommendations + "  Use reserved capacity for predictable workloads"
    }
    # Final validation
    # Progress stepNumber 10 -TotalSteps 10 -StepName "Validation" -Status "Verifying workspace health"
    if ($Action.ToLower() -notin @(" delete" )) {
$workspaceStatus = Invoke-AzureOperation -Operation {
            Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
        } -OperationName "Validate Workspace Status"
    }
    # Success summary
    Write-Host "" "INFO"
    Write-Host "                      AZURE SYNAPSE ANALYTICS WORKSPACE READY" -ForegroundColor Green
    Write-Host "" "INFO"
    if ($Action.ToLower() -eq " create" ) {
        Write-Host "Synapse Workspace Details:" -ForegroundColor Cyan
        Write-Host "    Workspace Name: $WorkspaceName" -ForegroundColor White
        Write-Host "    Resource Group: $ResourceGroupName" -ForegroundColor White
        Write-Host "    Location: $Location" -ForegroundColor White
        Write-Host "    Workspace URL: https://$WorkspaceName.dev.azuresynapse.net" -ForegroundColor White
        Write-Host "    SQL Admin: $SQLAdminUsername" -ForegroundColor White
        Write-Host "    Storage Account: $StorageAccountName" -ForegroundColor White
        Write-Host "    Status: $($workspaceStatus.ProvisioningState)" -ForegroundColor Green
        if ($SQLAdminPassword) {
            Write-Host "" "INFO"
            Write-Host "SQL Admin Credentials:" -ForegroundColor Yellow
            Write-Host "    Username: $SQLAdminUsername" -ForegroundColor Yellow
            Write-Host "    Password: [SecureString - Store in Key Vault]" -ForegroundColor Yellow
            Write-Host "   [WARN]  Store these credentials securely in Azure Key Vault!" -ForegroundColor Red
        }
        Write-Host "" "INFO"
        Write-Host " [LOCK] Security Assessment: $securityScore/$maxScore" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding" -ForegroundColor White
        }
        Write-Host "" "INFO"
        Write-Host "Cost Optimization:" -ForegroundColor Cyan
        foreach ($recommendation in $costRecommendations) {
            Write-Host "   $recommendation" -ForegroundColor White
        }
        Write-Host "" "INFO"
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "    Create SQL and Spark pools using CreateSQLPool/CreateSparkPool actions" -ForegroundColor White
        Write-Host "    Import data using Azure Data Factory integration" -ForegroundColor White
        Write-Host "    Configure Git integration for version control" -ForegroundColor White
        Write-Host "    Set up monitoring alerts and dashboards" -ForegroundColor White
        Write-Host "    Configure private endpoints for enhanced security" -ForegroundColor White
    }
    Write-Host "" "INFO"

} catch {

    Write-Host "" "INFO"
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "    Verify Synapse Analytics service availability in your region" -ForegroundColor White
    Write-Host "    Check subscription quotas and limits" -ForegroundColor White
    Write-Host "    Ensure proper permissions for resource creation" -ForegroundColor White
    Write-Host "    Validate storage account configuration" -ForegroundColor White
    Write-Host "    Check firewall rules and network connectivity" -ForegroundColor White
    Write-Host "" "INFO"
    throw
}

