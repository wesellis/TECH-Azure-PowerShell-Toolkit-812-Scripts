# Azure Synapse Analytics Workspace Manager
# Professional Azure automation script for enterprise data analytics
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0 | Enterprise data warehouse and analytics automation

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Create", "Delete", "GetInfo", "CreateSQLPool", "CreateSparkPool", "ManageFirewall")]
    [string]$Action = "Create",
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$FileSystemName = "synapsefs",
    
    [Parameter(Mandatory=$false)]
    [string]$SQLAdminUsername = "sqladmin",
    
    [Parameter(Mandatory=$false)]
    [string]$SQLAdminPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$SQLPoolName = "DataWarehouse",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("DW100c", "DW200c", "DW300c", "DW400c", "DW500c", "DW1000c")]
    [string]$SQLPoolSKU = "DW100c",
    
    [Parameter(Mandatory=$false)]
    [string]$SparkPoolName = "SparkPool",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Small", "Medium", "Large")]
    [string]$SparkPoolSize = "Small",
    
    [Parameter(Mandatory=$false)]
    [int]$SparkPoolMinNodes = 3,
    
    [Parameter(Mandatory=$false)]
    [int]$SparkPoolMaxNodes = 10,
    
    [Parameter(Mandatory=$false)]
    [string[]]$AllowedIPs = @(),
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableManagedVNet,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableDataExfiltrationProtection,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

# Professional banner
Show-Banner -ScriptName "Azure Synapse Analytics Workspace Manager" -Version "1.0" -Description "Enterprise data analytics and warehousing automation"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 10 -StepName "Azure Connection" -Status "Validating connection and Synapse services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Synapse', 'Az.Storage'))) {
        throw "Azure connection validation failed"
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 10 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    Write-Log "✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    switch ($Action.ToLower()) {
        "create" {
            # Create or validate storage account for Synapse
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Storage Account" -Status "Setting up primary storage account"
            
            if (-not $StorageAccountName) {
                $StorageAccountName = ($WorkspaceName + "storage").ToLower() -replace '[^a-z0-9]', ''
                if ($StorageAccountName.Length -gt 24) {
                    $StorageAccountName = $StorageAccountName.Substring(0, 24)
                }
            }
            
            $storageAccount = Invoke-AzureOperation -Operation {
                $existing = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Log "Using existing storage account: $StorageAccountName" -Level INFO
                    return $existing
                } else {
                    Write-Log "Creating new storage account: $StorageAccountName" -Level INFO
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
                    New-AzStorageAccount @storageParams
                }
            } -OperationName "Create/Get Storage Account"
            
            # Create file system
            $ctx = $storageAccount.Context
            $fileSystem = Invoke-AzureOperation -Operation {
                $existing = Get-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName -ErrorAction SilentlyContinue
                if (-not $existing) {
                    New-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName
                } else {
                    return $existing
                }
            } -OperationName "Create File System"
            
            Write-Log "✓ Storage account configured: $StorageAccountName" -Level SUCCESS

            # Generate secure password if not provided
            if (-not $SQLAdminPassword) {
                $SQLAdminPassword = -join ((65..90) + (97..122) + (48..57) + @(33,35,36,37,38,42,43,45,61,63,64) | Get-Random -Count 16 | ForEach-Object {[char]$_})
                Write-Log "Generated secure SQL admin password" -Level INFO
            }

            # Create Synapse workspace
            Write-ProgressStep -StepNumber 4 -TotalSteps 10 -StepName "Workspace Creation" -Status "Creating Synapse Analytics workspace"
            
            $workspaceParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $WorkspaceName
                Location = $Location
                DefaultDataLakeStorageAccountName = $StorageAccountName
                DefaultDataLakeStorageFilesystem = $FileSystemName
                SqlAdministratorLoginCredential = (New-Object System.Management.Automation.PSCredential($SQLAdminUsername, (ConvertTo-SecureString $SQLAdminPassword -AsPlainText -Force)))
                ManagedVirtualNetwork = $EnableManagedVNet
                PreventDataExfiltration = $EnableDataExfiltrationProtection
            }
            
            $workspace = Invoke-AzureOperation -Operation {
                New-AzSynapseWorkspace @workspaceParams
            } -OperationName "Create Synapse Workspace"
            
            Write-Log "✓ Synapse workspace created: $WorkspaceName" -Level SUCCESS
            Write-Log "✓ Workspace URL: https://$WorkspaceName.dev.azuresynapse.net" -Level INFO

            # Configure firewall rules
            Write-ProgressStep -StepNumber 5 -TotalSteps 10 -StepName "Firewall Configuration" -Status "Setting up firewall rules"
            
            # Allow Azure services
            Invoke-AzureOperation -Operation {
                New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name "AllowAllWindowsAzureIps" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0"
            } -OperationName "Create Azure Services Firewall Rule"
            
            # Add custom IP rules
            if ($AllowedIPs.Count -gt 0) {
                foreach ($ip in $AllowedIPs) {
                    $ruleName = "CustomRule-$($ip -replace '\.', '-')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name $ruleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName "Create Custom IP Firewall Rule"
                }
                Write-Log "✓ Custom firewall rules created for $($AllowedIPs.Count) IP addresses" -Level SUCCESS
            }
        }
        
        "createsqlpool" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "SQL Pool Creation" -Status "Creating dedicated SQL pool"
            
            $sqlPoolParams = @{
                WorkspaceName = $WorkspaceName
                Name = $SQLPoolName
                PerformanceLevel = $SQLPoolSKU
            }
            
            $sqlPool = Invoke-AzureOperation -Operation {
                New-AzSynapseSqlPool @sqlPoolParams
            } -OperationName "Create SQL Pool"
            
            Write-Log "✓ Dedicated SQL Pool created: $SQLPoolName ($SQLPoolSKU)" -Level SUCCESS
        }
        
        "createsparkpool" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Spark Pool Creation" -Status "Creating Apache Spark pool"
            
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
                SparkVersion = "3.3"
            }
            
            $sparkPool = Invoke-AzureOperation -Operation {
                New-AzSynapseSparkPool @sparkPoolParams
            } -OperationName "Create Spark Pool"
            
            Write-Log "✓ Apache Spark Pool created: $SparkPoolName ($SparkPoolSize)" -Level SUCCESS
        }
        
        "managefirewall" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Firewall Management" -Status "Managing firewall rules"
            
            $existingRules = Invoke-AzureOperation -Operation {
                Get-AzSynapseFirewallRule -WorkspaceName $WorkspaceName
            } -OperationName "Get Firewall Rules"
            
            Write-Host ""
            Write-Host "🔥 Current Firewall Rules for $WorkspaceName" -ForegroundColor Cyan
            Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            
            foreach ($rule in $existingRules) {
                Write-Host "• $($rule.Name): $($rule.StartIpAddress) - $($rule.EndIpAddress)" -ForegroundColor White
            }
            
            # Add new rules if specified
            if ($AllowedIPs.Count -gt 0) {
                Write-Log "Adding new firewall rules..." -Level INFO
                foreach ($ip in $AllowedIPs) {
                    $ruleName = "CustomRule-$($ip -replace '\.', '-')-$(Get-Date -Format 'yyyyMMdd')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name $ruleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName "Add Firewall Rule"
                    Write-Log "✓ Added firewall rule for IP: $ip" -Level SUCCESS
                }
            }
        }
        
        "getinfo" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Information Retrieval" -Status "Gathering workspace information"
            
            $workspace = Invoke-AzureOperation -Operation {
                Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
            } -OperationName "Get Workspace Info"
            
            $sqlPools = Invoke-AzureOperation -Operation {
                Get-AzSynapseSqlPool -WorkspaceName $WorkspaceName
            } -OperationName "Get SQL Pools"
            
            $sparkPools = Invoke-AzureOperation -Operation {
                Get-AzSynapseSparkPool -WorkspaceName $WorkspaceName
            } -OperationName "Get Spark Pools"
            
            Write-Host ""
            Write-Host "📊 Synapse Workspace Information" -ForegroundColor Cyan
            Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "Workspace Name: $($workspace.Name)" -ForegroundColor White
            Write-Host "Location: $($workspace.Location)" -ForegroundColor White
            Write-Host "Workspace URL: $($workspace.WebUrl)" -ForegroundColor White
            Write-Host "SQL Endpoint: $($workspace.SqlAdministratorLogin)" -ForegroundColor White
            Write-Host "Provisioning State: $($workspace.ProvisioningState)" -ForegroundColor Green
            
            if ($sqlPools.Count -gt 0) {
                Write-Host ""
                Write-Host "🗄️  SQL Pools:" -ForegroundColor Cyan
                foreach ($pool in $sqlPools) {
                    Write-Host "• $($pool.Name) - $($pool.Sku.Name) - $($pool.Status)" -ForegroundColor White
                }
            }
            
            if ($sparkPools.Count -gt 0) {
                Write-Host ""
                Write-Host "⚡ Spark Pools:" -ForegroundColor Cyan
                foreach ($pool in $sparkPools) {
                    Write-Host "• $($pool.Name) - $($pool.NodeSize) - Nodes: $($pool.NodeCount)" -ForegroundColor White
                }
            }
        }
        
        "delete" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Workspace Deletion" -Status "Removing Synapse workspace"
            
            $confirmation = Read-Host "Are you sure you want to delete the Synapse workspace '$WorkspaceName' and all its resources? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                Write-Log "Deletion cancelled by user" -Level WARN
                return
            }
            
            # Delete SQL pools first
            $sqlPools = Get-AzSynapseSqlPool -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
            foreach ($pool in $sqlPools) {
                Write-Log "Deleting SQL Pool: $($pool.Name)" -Level INFO
                Remove-AzSynapseSqlPool -WorkspaceName $WorkspaceName -Name $pool.Name -Force
            }
            
            # Delete Spark pools
            $sparkPools = Get-AzSynapseSparkPool -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
            foreach ($pool in $sparkPools) {
                Write-Log "Deleting Spark Pool: $($pool.Name)" -Level INFO
                Remove-AzSynapseSparkPool -WorkspaceName $WorkspaceName -Name $pool.Name -Force
            }
            
            # Delete workspace
            Invoke-AzureOperation -Operation {
                Remove-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Force
            } -OperationName "Delete Synapse Workspace"
            
            Write-Log "✓ Synapse workspace deleted: $WorkspaceName" -Level SUCCESS
        }
    }

    # Configure monitoring if enabled and creating workspace
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 6 -TotalSteps 10 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            
            if ($logAnalyticsWorkspace) {
                $resourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Synapse/workspaces/$WorkspaceName"
                
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = "$WorkspaceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("SynapseRbacOperations", "GatewayApiRequests", "BuiltinSqlReqsEnded", "IntegrationPipelineRuns", "IntegrationActivityRuns", "IntegrationTriggerRuns")
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

    # Apply enterprise tags if creating workspace
    if ($Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 7 -TotalSteps 10 -StepName "Tagging" -Status "Applying enterprise tags"
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
        
        $taggedResource = Invoke-AzureOperation -Operation {
            $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ResourceType "Microsoft.Synapse/workspaces"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
        } -OperationName "Apply Enterprise Tags"
    }

    # Security assessment
    Write-ProgressStep -StepNumber 8 -TotalSteps 10 -StepName "Security Assessment" -Status "Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 6
    $securityFindings = @()
    
    if ($Action.ToLower() -eq "create") {
        # Check managed VNet
        if ($EnableManagedVNet) {
            $securityScore++
            $securityFindings += "✓ Managed virtual network enabled"
        } else {
            $securityFindings += "⚠️  Managed VNet not enabled - consider for enhanced security"
        }
        
        # Check data exfiltration protection
        if ($EnableDataExfiltrationProtection) {
            $securityScore++
            $securityFindings += "✓ Data exfiltration protection enabled"
        } else {
            $securityFindings += "⚠️  Data exfiltration protection disabled"
        }
        
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings += "✓ Monitoring enabled"
        } else {
            $securityFindings += "⚠️  Monitoring not configured"
        }
        
        # Check firewall configuration
        if ($AllowedIPs.Count -gt 0) {
            $securityScore++
            $securityFindings += "✓ Custom firewall rules configured"
        } else {
            $securityFindings += "⚠️  Only Azure services allowed - configure specific IP rules"
        }
        
        # Check storage account security
        if ($storageAccount.EnableHttpsTrafficOnly) {
            $securityScore++
            $securityFindings += "✓ HTTPS-only traffic enforced on storage"
        }
        
        # Check region compliance
        if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
            $securityScore++
            $securityFindings += "✓ Deployed in compliant region"
        }
    }

    # Cost optimization recommendations
    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName "Cost Analysis" -Status "Analyzing cost optimization opportunities"
    
    $costRecommendations = @()
    
    if ($Action.ToLower() -eq "create") {
        $costRecommendations += "💰 Enable auto-pause for Spark pools to reduce costs during idle time"
        $costRecommendations += "💰 Use serverless SQL pool for exploratory workloads"
        $costRecommendations += "💰 Schedule SQL pool scaling based on usage patterns"
        $costRecommendations += "💰 Monitor storage costs and implement lifecycle policies"
        $costRecommendations += "💰 Use reserved capacity for predictable workloads"
    }

    # Final validation
    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName "Validation" -Status "Verifying workspace health"
    
    if ($Action.ToLower() -notin @("delete")) {
        $workspaceStatus = Invoke-AzureOperation -Operation {
            Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
        } -OperationName "Validate Workspace Status"
    }

    # Success summary
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                      AZURE SYNAPSE ANALYTICS WORKSPACE READY" -ForegroundColor Green  
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    if ($Action.ToLower() -eq "create") {
        Write-Host "📊 Synapse Workspace Details:" -ForegroundColor Cyan
        Write-Host "   • Workspace Name: $WorkspaceName" -ForegroundColor White
        Write-Host "   • Resource Group: $ResourceGroupName" -ForegroundColor White
        Write-Host "   • Location: $Location" -ForegroundColor White
        Write-Host "   • Workspace URL: https://$WorkspaceName.dev.azuresynapse.net" -ForegroundColor White
        Write-Host "   • SQL Admin: $SQLAdminUsername" -ForegroundColor White
        Write-Host "   • Storage Account: $StorageAccountName" -ForegroundColor White
        Write-Host "   • Status: $($workspaceStatus.ProvisioningState)" -ForegroundColor Green
        
        if ($SQLAdminPassword) {
            Write-Host ""
            Write-Host "🔑 SQL Admin Credentials:" -ForegroundColor Yellow
            Write-Host "   • Username: $SQLAdminUsername" -ForegroundColor Yellow
            Write-Host "   • Password: $SQLAdminPassword" -ForegroundColor Yellow
            Write-Host "   ⚠️  Store these credentials securely in Azure Key Vault!" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "🔒 Security Assessment: $securityScore/$maxScore" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "💰 Cost Optimization:" -ForegroundColor Cyan
        foreach ($recommendation in $costRecommendations) {
            Write-Host "   $recommendation" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "💡 Next Steps:" -ForegroundColor Cyan
        Write-Host "   • Create SQL and Spark pools using CreateSQLPool/CreateSparkPool actions" -ForegroundColor White
        Write-Host "   • Import data using Azure Data Factory integration" -ForegroundColor White
        Write-Host "   • Configure Git integration for version control" -ForegroundColor White
        Write-Host "   • Set up monitoring alerts and dashboards" -ForegroundColor White
        Write-Host "   • Configure private endpoints for enhanced security" -ForegroundColor White
    }
    
    Write-Host ""

    Write-Log "✅ Azure Synapse Analytics workspace '$WorkspaceName' operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log "❌ Synapse Analytics operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Host ""
    Write-Host "🔧 Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "   • Verify Synapse Analytics service availability in your region" -ForegroundColor White
    Write-Host "   • Check subscription quotas and limits" -ForegroundColor White
    Write-Host "   • Ensure proper permissions for resource creation" -ForegroundColor White
    Write-Host "   • Validate storage account configuration" -ForegroundColor White
    Write-Host "   • Check firewall rules and network connectivity" -ForegroundColor White
    Write-Host ""
    
    exit 1
}

Write-Progress -Activity "Synapse Analytics Workspace Management" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
