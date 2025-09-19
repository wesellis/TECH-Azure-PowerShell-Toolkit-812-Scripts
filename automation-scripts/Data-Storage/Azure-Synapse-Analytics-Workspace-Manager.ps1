#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Azure Synapse Analytics Workspace Manager
# Professional Azure automation script for enterprise data analytics
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
    [SecureString]$SQLAdminPassword,
    
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

#region Functions

# Import common functions
# Module import removed - use #Requires instead

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
    
    Write-Log "[OK] Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

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
                    New-AzStorageAccount -ErrorAction Stop @storageParams
                }
            } -OperationName "Create/Get Storage Account"
            
            # Create file system
            $ctx = $storageAccount.Context
            $null = Invoke-AzureOperation -Operation {
                $existing = Get-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName -ErrorAction SilentlyContinue
                if (-not $existing) {
                    New-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName
                    Write-Log "[OK] Created file system: $FileSystemName" -Level SUCCESS
                } else {
                    Write-Log "[OK] Using existing file system: $FileSystemName" -Level INFO
                    return $existing
                }
            } -OperationName "Create File System"
            
            Write-Log "[OK] Storage account configured: $StorageAccountName" -Level SUCCESS

            # Generate secure password if not provided
            if (-not $SQLAdminPassword) {
                $passwordText = -join ((65..90) + (97..122) + (48..57) + @(33,35,36,37,38,42,43,45,61,63,64) | Get-Random -Count 16 | ForEach-Object {[char]$_})
                $SQLAdminPassword = ConvertTo-SecureString $passwordText -AsPlainText -Force
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
                SqlAdministratorLoginCredential = (New-Object -ErrorAction Stop System.Management.Automation.PSCredential($SQLAdminUsername, $SQLAdminPassword))
                ManagedVirtualNetwork = $EnableManagedVNet
                PreventDataExfiltration = $EnableDataExfiltrationProtection
            }
            
            $workspace = Invoke-AzureOperation -Operation {
                New-AzSynapseWorkspace -ErrorAction Stop @workspaceParams
            } -OperationName "Create Synapse Workspace"
            
            Write-Log "[OK] Synapse workspace created: $WorkspaceName" -Level SUCCESS
            Write-Log "[OK] Workspace URL: https://$WorkspaceName.dev.azuresynapse.net" -Level INFO

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
                Write-Log "[OK] Custom firewall rules created for $($AllowedIPs.Count) IP addresses" -Level SUCCESS
            }
        }
        
        "createsqlpool" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "SQL Pool Creation" -Status "Creating dedicated SQL pool"
            
            $sqlPoolParams = @{
                WorkspaceName = $WorkspaceName
                Name = $SQLPoolName
                PerformanceLevel = $SQLPoolSKU
            }
            
            $null = Invoke-AzureOperation -Operation {
                New-AzSynapseSqlPool -ErrorAction Stop @sqlPoolParams
            } -OperationName "Create SQL Pool"
            
            Write-Log "[OK] Dedicated SQL Pool created: $SQLPoolName ($SQLPoolSKU)" -Level SUCCESS
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
            
            $null = Invoke-AzureOperation -Operation {
                New-AzSynapseSparkPool -ErrorAction Stop @sparkPoolParams
            } -OperationName "Create Spark Pool"
            
            Write-Log "[OK] Apache Spark Pool created: $SparkPoolName ($SparkPoolSize)" -Level SUCCESS
        }
        
        "managefirewall" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Firewall Management" -Status "Managing firewall rules"
            
            $existingRules = Invoke-AzureOperation -Operation {
                Get-AzSynapseFirewallRule -WorkspaceName $WorkspaceName
            } -OperationName "Get Firewall Rules"
            
            Write-Information ""
            Write-Information "� Current Firewall Rules for $WorkspaceName"
            Write-Information "════════════════════════════════════════════════════════════════════"
            
            foreach ($rule in $existingRules) {
                Write-Information "• $($rule.Name): $($rule.StartIpAddress) - $($rule.EndIpAddress)"
            }
            
            # Add new rules if specified
            if ($AllowedIPs.Count -gt 0) {
                Write-Log "Adding new firewall rules..." -Level INFO
                foreach ($ip in $AllowedIPs) {
                    $ruleName = "CustomRule-$($ip -replace '\.', '-')-$(Get-Date -Format 'yyyyMMdd')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name $ruleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName "Add Firewall Rule"
                    Write-Log "[OK] Added firewall rule for IP: $ip" -Level SUCCESS
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
            
            Write-Information ""
            Write-Information " Synapse Workspace Information"
            Write-Information "════════════════════════════════════════════════════════════════════"
            Write-Information "Workspace Name: $($workspace.Name)"
            Write-Information "Location: $($workspace.Location)"
            Write-Information "Workspace URL: $($workspace.WebUrl)"
            Write-Information "SQL Endpoint: $($workspace.SqlAdministratorLogin)"
            Write-Information "Provisioning State: $($workspace.ProvisioningState)"
            
            if ($sqlPools.Count -gt 0) {
                Write-Information ""
                Write-Information "🗄  SQL Pools:"
                foreach ($pool in $sqlPools) {
                    Write-Information "• $($pool.Name) - $($pool.Sku.Name) - $($pool.Status)"
                }
            }
            
            if ($sparkPools.Count -gt 0) {
                Write-Information ""
                Write-Information "[!] Spark Pools:"
                foreach ($pool in $sparkPools) {
                    Write-Information "• $($pool.Name) - $($pool.NodeSize) - Nodes: $($pool.NodeCount)"
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
            
            Write-Log "[OK] Synapse workspace deleted: $WorkspaceName" -Level SUCCESS
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
                
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {
                Write-Log "[WARN]️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName "Configure Monitoring"
        
        if ($diagnosticSettings) {
            Write-Log "[OK] Monitoring configured with diagnostic settings" -Level SUCCESS
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
        
        $null = Invoke-AzureOperation -Operation {
            $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ResourceType "Microsoft.Synapse/workspaces"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
            Write-Log "[OK] Applied enterprise tags to workspace" -Level SUCCESS
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
            $securityFindings += "[OK] Managed virtual network enabled"
        } else {
            $securityFindings += "[WARN]️  Managed VNet not enabled - consider for enhanced security"
        }
        
        # Check data exfiltration protection
        if ($EnableDataExfiltrationProtection) {
            $securityScore++
            $securityFindings += "[OK] Data exfiltration protection enabled"
        } else {
            $securityFindings += "[WARN]️  Data exfiltration protection disabled"
        }
        
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings += "[OK] Monitoring enabled"
        } else {
            $securityFindings += "[WARN]️  Monitoring not configured"
        }
        
        # Check firewall configuration
        if ($AllowedIPs.Count -gt 0) {
            $securityScore++
            $securityFindings += "[OK] Custom firewall rules configured"
        } else {
            $securityFindings += "[WARN]️  Only Azure services allowed - configure specific IP rules"
        }
        
        # Check storage account security
        if ($storageAccount.EnableHttpsTrafficOnly) {
            $securityScore++
            $securityFindings += "[OK] HTTPS-only traffic enforced on storage"
        }
        
        # Check region compliance
        if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
            $securityScore++
            $securityFindings += "[OK] Deployed in compliant region"
        }
    }

    # Cost optimization recommendations
    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName "Cost Analysis" -Status "Analyzing cost optimization opportunities"
    
    $costRecommendations = @()
    
    if ($Action.ToLower() -eq "create") {
        $costRecommendations += " Enable auto-pause for Spark pools to reduce costs during idle time"
        $costRecommendations += " Use serverless SQL pool for exploratory workloads"
        $costRecommendations += " Schedule SQL pool scaling based on usage patterns"
        $costRecommendations += " Monitor storage costs and implement lifecycle policies"
        $costRecommendations += " Use reserved capacity for predictable workloads"
    }

    # Final validation
    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName "Validation" -Status "Verifying workspace health"
    
    if ($Action.ToLower() -notin @("delete")) {
        $workspaceStatus = Invoke-AzureOperation -Operation {
            Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
        } -OperationName "Validate Workspace Status"
    }

    # Success summary
    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                      AZURE SYNAPSE ANALYTICS WORKSPACE READY"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    
    if ($Action.ToLower() -eq "create") {
        Write-Information " Synapse Workspace Details:"
        Write-Information "   • Workspace Name: $WorkspaceName"
        Write-Information "   • Resource Group: $ResourceGroupName"
        Write-Information "   • Location: $Location"
        Write-Information "   • Workspace URL: https://$WorkspaceName.dev.azuresynapse.net"
        Write-Information "   • SQL Admin: $SQLAdminUsername"
        Write-Information "   • Storage Account: $StorageAccountName"
        Write-Information "   • Status: $($workspaceStatus.ProvisioningState)"
        
        if ($SQLAdminPassword) {
            Write-Information ""
            Write-Information "� SQL Admin Credentials:"
            Write-Information "   • Username: $SQLAdminUsername"
            Write-Information "   • Password: [SecureString - Store in Key Vault]"
            Write-Information "   [WARN]  Store these credentials securely in Azure Key Vault!"
        }
        
        Write-Information ""
        Write-Information "[LOCK] Security Assessment: $securityScore/$maxScore"
        foreach ($finding in $securityFindings) {
            Write-Information "   $finding"
        }
        
        Write-Information ""
        Write-Information " Cost Optimization:"
        foreach ($recommendation in $costRecommendations) {
            Write-Information "   $recommendation"
        }
        
        Write-Information ""
        Write-Information "� Next Steps:"
        Write-Information "   • Create SQL and Spark pools using CreateSQLPool/CreateSparkPool actions"
        Write-Information "   • Import data using Azure Data Factory integration"
        Write-Information "   • Configure Git integration for version control"
        Write-Information "   • Set up monitoring alerts and dashboards"
        Write-Information "   • Configure private endpoints for enhanced security"
    }
    
    Write-Information ""

    Write-Log " Azure Synapse Analytics workspace '$WorkspaceName' operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log " Synapse Analytics operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Information ""
    Write-Information " Troubleshooting Tips:"
    Write-Information "   • Verify Synapse Analytics service availability in your region"
    Write-Information "   • Check subscription quotas and limits"
    Write-Information "   • Ensure proper permissions for resource creation"
    Write-Information "   • Validate storage account configuration"
    Write-Information "   • Check firewall rules and network connectivity"
    Write-Information ""
    
    exit 1
}

Write-Progress -Activity "Synapse Analytics Workspace Management" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO


#endregion
