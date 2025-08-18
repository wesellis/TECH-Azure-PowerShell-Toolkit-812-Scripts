<#
.SYNOPSIS
    Azure Synapse Analytics Workspace Manager

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
    We Enhanced Azure Synapse Analytics Workspace Manager

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
    [string]$WEWorkspaceName,
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " East US" ,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Create" , " Delete" , " GetInfo" , " CreateSQLPool" , " CreateSparkPool" , " ManageFirewall" )]
    [string]$WEAction = " Create" ,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEStorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$WEFileSystemName = " synapsefs" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WESQLAdminUsername = " sqladmin" ,
    
    [Parameter(Mandatory=$false)]
    [SecureString]$WESQLAdminPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$WESQLPoolName = " DataWarehouse" ,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" DW100c" , " DW200c" , " DW300c" , " DW400c" , " DW500c" , " DW1000c" )]
    [string]$WESQLPoolSKU = " DW100c" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WESparkPoolName = " SparkPool" ,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Small" , " Medium" , " Large" )]
    [string]$WESparkPoolSize = " Small" ,
    
    [Parameter(Mandatory=$false)]
    [int]$WESparkPoolMinNodes = 3,
    
    [Parameter(Mandatory=$false)]
    [int]$WESparkPoolMaxNodes = 10,
    
    [Parameter(Mandatory=$false)]
    [string[]]$WEAllowedIPs = @(),
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableManagedVNet,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableDataExfiltrationProtection,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableMonitoring
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force


Show-Banner -ScriptName " Azure Synapse Analytics Workspace Manager" -Version " 1.0" -Description " Enterprise data analytics and warehousing automation"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 10 -StepName " Azure Connection" -Status " Validating connection and Synapse services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Synapse', 'Az.Storage'))) {
        throw " Azure connection validation failed"
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 10 -StepName " Resource Group Validation" -Status " Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction Stop
    } -OperationName " Get Resource Group"
    
    Write-Log " ✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    switch ($WEAction.ToLower()) {
        " create" {
            # Create or validate storage account for Synapse
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Storage Account" -Status " Setting up primary storage account"
            
            if (-not $WEStorageAccountName) {
                $WEStorageAccountName = ($WEWorkspaceName + " storage" ).ToLower() -replace '[^a-z0-9]', ''
                if ($WEStorageAccountName.Length -gt 24) {
                    $WEStorageAccountName = $WEStorageAccountName.Substring(0, 24)
                }
            }
            
            $storageAccount = Invoke-AzureOperation -Operation {
                $existing = Get-AzStorageAccount -ResourceGroupName $WEResourceGroupName -Name $WEStorageAccountName -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Log " Using existing storage account: $WEStorageAccountName" -Level INFO
                    return $existing
                } else {
                    Write-Log " Creating new storage account: $WEStorageAccountName" -Level INFO
                    $storageParams = @{
                        ResourceGroupName = $WEResourceGroupName
                        Name = $WEStorageAccountName
                        Location = $WELocation
                        SkuName = " Standard_LRS"
                        Kind = " StorageV2"
                        EnableHierarchicalNamespace = $true
                        EnableHttpsTrafficOnly = $true
                        MinimumTlsVersion = " TLS1_2"
                    }
                    New-AzStorageAccount @storageParams
                }
            } -OperationName " Create/Get Storage Account"
            
            # Create file system
            $ctx = $storageAccount.Context
            $null = Invoke-AzureOperation -Operation {
                $existing = Get-AzDataLakeGen2FileSystem -Context $ctx -Name $WEFileSystemName -ErrorAction SilentlyContinue
                if (-not $existing) {
                    New-AzDataLakeGen2FileSystem -Context $ctx -Name $WEFileSystemName
                    Write-Log " ✓ Created file system: $WEFileSystemName" -Level SUCCESS
                } else {
                    Write-Log " ✓ Using existing file system: $WEFileSystemName" -Level INFO
                    return $existing
                }
            } -OperationName " Create File System"
            
            Write-Log " ✓ Storage account configured: $WEStorageAccountName" -Level SUCCESS

            # Generate secure password if not provided
            if (-not $WESQLAdminPassword) {
                $passwordText = -join ((65..90) + (97..122) + (48..57) + @(33,35,36,37,38,42,43,45,61,63,64) | Get-Random -Count 16 | ForEach-Object {[char]$_})
                $WESQLAdminPassword = ConvertTo-SecureString $passwordText -AsPlainText -Force
                Write-Log " Generated secure SQL admin password" -Level INFO
            }

            # Create Synapse workspace
            Write-ProgressStep -StepNumber 4 -TotalSteps 10 -StepName " Workspace Creation" -Status " Creating Synapse Analytics workspace"
            
            $workspaceParams = @{
                ResourceGroupName = $WEResourceGroupName
                Name = $WEWorkspaceName
                Location = $WELocation
                DefaultDataLakeStorageAccountName = $WEStorageAccountName
                DefaultDataLakeStorageFilesystem = $WEFileSystemName
                SqlAdministratorLoginCredential = (New-Object System.Management.Automation.PSCredential($WESQLAdminUsername, $WESQLAdminPassword))
                ManagedVirtualNetwork = $WEEnableManagedVNet
                PreventDataExfiltration = $WEEnableDataExfiltrationProtection
            }
            
            $workspace = Invoke-AzureOperation -Operation {
                New-AzSynapseWorkspace @workspaceParams
            } -OperationName " Create Synapse Workspace"
            
            Write-Log " ✓ Synapse workspace created: $WEWorkspaceName" -Level SUCCESS
            Write-Log " ✓ Workspace URL: https://$WEWorkspaceName.dev.azuresynapse.net" -Level INFO

            # Configure firewall rules
            Write-ProgressStep -StepNumber 5 -TotalSteps 10 -StepName " Firewall Configuration" -Status " Setting up firewall rules"
            
            # Allow Azure services
            Invoke-AzureOperation -Operation {
                New-AzSynapseFirewallRule -WorkspaceName $WEWorkspaceName -Name " AllowAllWindowsAzureIps" -StartIpAddress " 0.0.0.0" -EndIpAddress " 0.0.0.0"
            } -OperationName " Create Azure Services Firewall Rule"
            
            # Add custom IP rules
            if ($WEAllowedIPs.Count -gt 0) {
                foreach ($ip in $WEAllowedIPs) {
                    $ruleName = " CustomRule-$($ip -replace '\.', '-')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WEWorkspaceName -Name $ruleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName " Create Custom IP Firewall Rule"
                }
                Write-Log " ✓ Custom firewall rules created for $($WEAllowedIPs.Count) IP addresses" -Level SUCCESS
            }
        }
        
        " createsqlpool" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " SQL Pool Creation" -Status " Creating dedicated SQL pool"
            
            $sqlPoolParams = @{
                WorkspaceName = $WEWorkspaceName
                Name = $WESQLPoolName
                PerformanceLevel = $WESQLPoolSKU
            }
            
            $null = Invoke-AzureOperation -Operation {
                New-AzSynapseSqlPool @sqlPoolParams
            } -OperationName " Create SQL Pool"
            
            Write-Log " ✓ Dedicated SQL Pool created: $WESQLPoolName ($WESQLPoolSKU)" -Level SUCCESS
        }
        
        " createsparkpool" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Spark Pool Creation" -Status " Creating Apache Spark pool"
            
            $sparkPoolParams = @{
                WorkspaceName = $WEWorkspaceName
                Name = $WESparkPoolName
                NodeSize = $WESparkPoolSize
                NodeCount = $WESparkPoolMinNodes
                AutoScaleMinNodeCount = $WESparkPoolMinNodes
                AutoScaleMaxNodeCount = $WESparkPoolMaxNodes
                AutoScaleEnabled = $true
                AutoPauseEnabled = $true
                AutoPauseDelayInMinute = 15
                SparkVersion = " 3.3"
            }
            
            $null = Invoke-AzureOperation -Operation {
                New-AzSynapseSparkPool @sparkPoolParams
            } -OperationName " Create Spark Pool"
            
            Write-Log " ✓ Apache Spark Pool created: $WESparkPoolName ($WESparkPoolSize)" -Level SUCCESS
        }
        
        " managefirewall" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Firewall Management" -Status " Managing firewall rules"
            
            $existingRules = Invoke-AzureOperation -Operation {
                Get-AzSynapseFirewallRule -WorkspaceName $WEWorkspaceName
            } -OperationName " Get Firewall Rules"
            
            Write-WELog "" " INFO"
            Write-WELog " 🔥 Current Firewall Rules for $WEWorkspaceName" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            
            foreach ($rule in $existingRules) {
                Write-WELog " • $($rule.Name): $($rule.StartIpAddress) - $($rule.EndIpAddress)" " INFO" -ForegroundColor White
            }
            
            # Add new rules if specified
            if ($WEAllowedIPs.Count -gt 0) {
                Write-Log " Adding new firewall rules..." -Level INFO
                foreach ($ip in $WEAllowedIPs) {
                    $ruleName = " CustomRule-$($ip -replace '\.', '-')-$(Get-Date -Format 'yyyyMMdd')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WEWorkspaceName -Name $ruleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName " Add Firewall Rule"
                    Write-Log " ✓ Added firewall rule for IP: $ip" -Level SUCCESS
                }
            }
        }
        
        " getinfo" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Information Retrieval" -Status " Gathering workspace information"
            
            $workspace = Invoke-AzureOperation -Operation {
                Get-AzSynapseWorkspace -ResourceGroupName $WEResourceGroupName -Name $WEWorkspaceName
            } -OperationName " Get Workspace Info"
            
            $sqlPools = Invoke-AzureOperation -Operation {
                Get-AzSynapseSqlPool -WorkspaceName $WEWorkspaceName
            } -OperationName " Get SQL Pools"
            
            $sparkPools = Invoke-AzureOperation -Operation {
                Get-AzSynapseSparkPool -WorkspaceName $WEWorkspaceName
            } -OperationName " Get Spark Pools"
            
            Write-WELog "" " INFO"
            Write-WELog " 📊 Synapse Workspace Information" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            Write-WELog " Workspace Name: $($workspace.Name)" " INFO" -ForegroundColor White
            Write-WELog " Location: $($workspace.Location)" " INFO" -ForegroundColor White
            Write-WELog " Workspace URL: $($workspace.WebUrl)" " INFO" -ForegroundColor White
            Write-WELog " SQL Endpoint: $($workspace.SqlAdministratorLogin)" " INFO" -ForegroundColor White
            Write-WELog " Provisioning State: $($workspace.ProvisioningState)" " INFO" -ForegroundColor Green
            
            if ($sqlPools.Count -gt 0) {
                Write-WELog "" " INFO"
                Write-WELog " 🗄️  SQL Pools:" " INFO" -ForegroundColor Cyan
                foreach ($pool in $sqlPools) {
                    Write-WELog " • $($pool.Name) - $($pool.Sku.Name) - $($pool.Status)" " INFO" -ForegroundColor White
                }
            }
            
            if ($sparkPools.Count -gt 0) {
                Write-WELog "" " INFO"
                Write-WELog " ⚡ Spark Pools:" " INFO" -ForegroundColor Cyan
                foreach ($pool in $sparkPools) {
                    Write-WELog " • $($pool.Name) - $($pool.NodeSize) - Nodes: $($pool.NodeCount)" " INFO" -ForegroundColor White
                }
            }
        }
        
        " delete" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Workspace Deletion" -Status " Removing Synapse workspace"
            
            $confirmation = Read-Host " Are you sure you want to delete the Synapse workspace '$WEWorkspaceName' and all its resources? (yes/no)"
            if ($confirmation.ToLower() -ne " yes" ) {
                Write-Log " Deletion cancelled by user" -Level WARN
                return
            }
            
            # Delete SQL pools first
            $sqlPools = Get-AzSynapseSqlPool -WorkspaceName $WEWorkspaceName -ErrorAction SilentlyContinue
            foreach ($pool in $sqlPools) {
                Write-Log " Deleting SQL Pool: $($pool.Name)" -Level INFO
                Remove-AzSynapseSqlPool -WorkspaceName $WEWorkspaceName -Name $pool.Name -Force
            }
            
            # Delete Spark pools
            $sparkPools = Get-AzSynapseSparkPool -WorkspaceName $WEWorkspaceName -ErrorAction SilentlyContinue
            foreach ($pool in $sparkPools) {
                Write-Log " Deleting Spark Pool: $($pool.Name)" -Level INFO
                Remove-AzSynapseSparkPool -WorkspaceName $WEWorkspaceName -Name $pool.Name -Force
            }
            
            # Delete workspace
            Invoke-AzureOperation -Operation {
                Remove-AzSynapseWorkspace -ResourceGroupName $WEResourceGroupName -Name $WEWorkspaceName -Force
            } -OperationName " Delete Synapse Workspace"
            
            Write-Log " ✓ Synapse workspace deleted: $WEWorkspaceName" -Level SUCCESS
        }
    }

    # Configure monitoring if enabled and creating workspace
    if ($WEEnableMonitoring -and $WEAction.ToLower() -eq " create" ) {
        Write-ProgressStep -StepNumber 6 -TotalSteps 10 -StepName " Monitoring Setup" -Status " Configuring diagnostic settings"
        
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName | Select-Object -First 1
            
            if ($logAnalyticsWorkspace) {
                $resourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$WEResourceGroupName/providers/Microsoft.Synapse/workspaces/$WEWorkspaceName"
                
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = " $WEWorkspaceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @(" SynapseRbacOperations" , " GatewayApiRequests" , " BuiltinSqlReqsEnded" , " IntegrationPipelineRuns" , " IntegrationActivityRuns" , " IntegrationTriggerRuns" )
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

    # Apply enterprise tags if creating workspace
    if ($WEAction.ToLower() -eq " create" ) {
        Write-ProgressStep -StepNumber 7 -TotalSteps 10 -StepName " Tagging" -Status " Applying enterprise tags"
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
            $resource = Get-AzResource -ResourceGroupName $WEResourceGroupName -Name $WEWorkspaceName -ResourceType " Microsoft.Synapse/workspaces"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
            Write-Log " ✓ Applied enterprise tags to workspace" -Level SUCCESS
        } -OperationName " Apply Enterprise Tags"
    }

    # Security assessment
    Write-ProgressStep -StepNumber 8 -TotalSteps 10 -StepName " Security Assessment" -Status " Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 6
    $securityFindings = @()
    
    if ($WEAction.ToLower() -eq " create" ) {
        # Check managed VNet
        if ($WEEnableManagedVNet) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Managed virtual network enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Managed VNet not enabled - consider for enhanced security"
        }
        
        # Check data exfiltration protection
        if ($WEEnableDataExfiltrationProtection) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Data exfiltration protection enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Data exfiltration protection disabled"
        }
        
        # Check monitoring
        if ($WEEnableMonitoring) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Monitoring enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Monitoring not configured"
        }
        
        # Check firewall configuration
        if ($WEAllowedIPs.Count -gt 0) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Custom firewall rules configured"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Only Azure services allowed - configure specific IP rules"
        }
        
        # Check storage account security
        if ($storageAccount.EnableHttpsTrafficOnly) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ HTTPS-only traffic enforced on storage"
        }
        
        # Check region compliance
        if ($WELocation -in @(" East US" , " West Europe" , " Southeast Asia" )) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Deployed in compliant region"
        }
    }

    # Cost optimization recommendations
    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName " Cost Analysis" -Status " Analyzing cost optimization opportunities"
    
    $costRecommendations = @()
    
    if ($WEAction.ToLower() -eq " create" ) {
        $costRecommendations = $costRecommendations + " 💰 Enable auto-pause for Spark pools to reduce costs during idle time"
        $costRecommendations = $costRecommendations + " 💰 Use serverless SQL pool for exploratory workloads"
        $costRecommendations = $costRecommendations + " 💰 Schedule SQL pool scaling based on usage patterns"
        $costRecommendations = $costRecommendations + " 💰 Monitor storage costs and implement lifecycle policies"
       ;  $costRecommendations = $costRecommendations + " 💰 Use reserved capacity for predictable workloads"
    }

    # Final validation
    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName " Validation" -Status " Verifying workspace health"
    
    if ($WEAction.ToLower() -notin @(" delete" )) {
       ;  $workspaceStatus = Invoke-AzureOperation -Operation {
            Get-AzSynapseWorkspace -ResourceGroupName $WEResourceGroupName -Name $WEWorkspaceName
        } -OperationName " Validate Workspace Status"
    }

    # Success summary
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                      AZURE SYNAPSE ANALYTICS WORKSPACE READY" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    
    if ($WEAction.ToLower() -eq " create" ) {
        Write-WELog " 📊 Synapse Workspace Details:" " INFO" -ForegroundColor Cyan
        Write-WELog "   • Workspace Name: $WEWorkspaceName" " INFO" -ForegroundColor White
        Write-WELog "   • Resource Group: $WEResourceGroupName" " INFO" -ForegroundColor White
        Write-WELog "   • Location: $WELocation" " INFO" -ForegroundColor White
        Write-WELog "   • Workspace URL: https://$WEWorkspaceName.dev.azuresynapse.net" " INFO" -ForegroundColor White
        Write-WELog "   • SQL Admin: $WESQLAdminUsername" " INFO" -ForegroundColor White
        Write-WELog "   • Storage Account: $WEStorageAccountName" " INFO" -ForegroundColor White
        Write-WELog "   • Status: $($workspaceStatus.ProvisioningState)" " INFO" -ForegroundColor Green
        
        if ($WESQLAdminPassword) {
            Write-WELog "" " INFO"
            Write-WELog " 🔑 SQL Admin Credentials:" " INFO" -ForegroundColor Yellow
            Write-WELog "   • Username: $WESQLAdminUsername" " INFO" -ForegroundColor Yellow
            Write-WELog "   • Password: [SecureString - Store in Key Vault]" " INFO" -ForegroundColor Yellow
            Write-WELog "   ⚠️  Store these credentials securely in Azure Key Vault!" " INFO" -ForegroundColor Red
        }
        
        Write-WELog "" " INFO"
        Write-WELog " 🔒 Security Assessment: $securityScore/$maxScore" " INFO" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-WELog "   $finding" " INFO" -ForegroundColor White
        }
        
        Write-WELog "" " INFO"
        Write-WELog " 💰 Cost Optimization:" " INFO" -ForegroundColor Cyan
        foreach ($recommendation in $costRecommendations) {
            Write-WELog "   $recommendation" " INFO" -ForegroundColor White
        }
        
        Write-WELog "" " INFO"
        Write-WELog " 💡 Next Steps:" " INFO" -ForegroundColor Cyan
        Write-WELog "   • Create SQL and Spark pools using CreateSQLPool/CreateSparkPool actions" " INFO" -ForegroundColor White
        Write-WELog "   • Import data using Azure Data Factory integration" " INFO" -ForegroundColor White
        Write-WELog "   • Configure Git integration for version control" " INFO" -ForegroundColor White
        Write-WELog "   • Set up monitoring alerts and dashboards" " INFO" -ForegroundColor White
        Write-WELog "   • Configure private endpoints for enhanced security" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"

    Write-Log " ✅ Azure Synapse Analytics workspace '$WEWorkspaceName' operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log " ❌ Synapse Analytics operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-WELog "" " INFO"
    Write-WELog " 🔧 Troubleshooting Tips:" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Verify Synapse Analytics service availability in your region" " INFO" -ForegroundColor White
    Write-WELog "   • Check subscription quotas and limits" " INFO" -ForegroundColor White
    Write-WELog "   • Ensure proper permissions for resource creation" " INFO" -ForegroundColor White
    Write-WELog "   • Validate storage account configuration" " INFO" -ForegroundColor White
    Write-WELog "   • Check firewall rules and network connectivity" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"
    
    exit 1
}

Write-Progress -Activity " Synapse Analytics Workspace Management" -Completed
Write-Log " Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================