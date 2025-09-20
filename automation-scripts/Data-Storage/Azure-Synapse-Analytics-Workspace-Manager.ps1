<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Synapse Analytics Workspace Manager
#
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$WorkspaceName,
    [Parameter()]
    [string]$Location = "East US",
    [Parameter()]
    [ValidateSet("Create", "Delete", "GetInfo", "CreateSQLPool", "CreateSparkPool", "ManageFirewall")]
    [string]$Action = "Create",
    [Parameter()]
    [string]$StorageAccountName,
    [Parameter()]
    [string]$FileSystemName = "synapsefs",
    [Parameter()]
    [string]$SQLAdminUsername = "sqladmin",
    [Parameter()]
    [SecureString]$SQLAdminPassword,
    [Parameter()]
    [string]$SQLPoolName = "DataWarehouse",
    [Parameter()]
    [ValidateSet("DW100c", "DW200c", "DW300c", "DW400c", "DW500c", "DW1000c")]
    [string]$SQLPoolSKU = "DW100c",
    [Parameter()]
    [string]$SparkPoolName = "SparkPool",
    [Parameter()]
    [ValidateSet("Small", "Medium", "Large")]
    [string]$SparkPoolSize = "Small",
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
try {
    # Test Azure connection
        if (-not (Get-AzContext)) { Connect-AzAccount }
    # Validate resource group
        $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    switch ($Action.ToLower()) {
        "create" {
            # Create or validate storage account for Synapse
                if (-not $StorageAccountName) {
                $StorageAccountName = ($WorkspaceName + "storage").ToLower() -replace '[^a-z0-9]', ''
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
                
            }
        }
        "createsqlpool" {
                $sqlPoolParams = @{
                WorkspaceName = $WorkspaceName
                Name = $SQLPoolName
                PerformanceLevel = $SQLPoolSKU
            }
            $null = Invoke-AzureOperation -Operation {
                New-AzSynapseSqlPool -ErrorAction Stop @sqlPoolParams
            } -OperationName "Create SQL Pool"
            
        }
        "createsparkpool" {
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
            
        }
        "managefirewall" {
                $existingRules = Invoke-AzureOperation -Operation {
                Get-AzSynapseFirewallRule -WorkspaceName $WorkspaceName
            } -OperationName "Get Firewall Rules"
            Write-Host ""
            foreach ($rule in $existingRules) {
                Write-Host " $($rule.Name): $($rule.StartIpAddress) - $($rule.EndIpAddress)"
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
        "getinfo" {
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
            Write-Host "Synapse Workspace Information"
            Write-Host "Workspace Name: $($workspace.Name)"
            Write-Host "Location: $($workspace.Location)"
            Write-Host "Workspace URL: $($workspace.WebUrl)"
            Write-Host "SQL Endpoint: $($workspace.SqlAdministratorLogin)"
            Write-Host "Provisioning State: $($workspace.ProvisioningState)"
            if ($sqlPools.Count -gt 0) {
                Write-Host ""
                Write-Host "SQL Pools:"
                foreach ($pool in $sqlPools) {
                    Write-Host " $($pool.Name) - $($pool.Sku.Name) - $($pool.Status)"
                }
            }
            if ($sparkPools.Count -gt 0) {
                Write-Host ""
                Write-Host "[!] Spark Pools:"
                foreach ($pool in $sparkPools) {
                    Write-Host " $($pool.Name) - $($pool.NodeSize) - Nodes: $($pool.NodeCount)"
                }
            }
        }
        "delete" {
                $confirmation = Read-Host "Are you sure you want to delete the Synapse workspace '$WorkspaceName' and all its resources? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                
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
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
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
                
                return $null
            }
        } -OperationName "Configure Monitoring"
        if ($diagnosticSettings) {
            
        }
    }
    # Apply enterprise tags if creating workspace
    if ($Action.ToLower() -eq "create") {
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
        $securityScore = 0
    $maxScore = 6
    $securityFindings = @()
    if ($Action.ToLower() -eq "create") {
        # Check managed VNet
        if ($EnableManagedVNet) {
            $securityScore++
            $securityFindings += "[OK] Managed virtual network enabled"
        } else {
            $securityFindings += "[WARN]  Managed VNet not enabled - consider for enhanced security"
        }
        # Check data exfiltration protection
        if ($EnableDataExfiltrationProtection) {
            $securityScore++
            $securityFindings += "[OK] Data exfiltration protection enabled"
        } else {
            $securityFindings += "[WARN]  Data exfiltration protection disabled"
        }
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings += "[OK] Monitoring enabled"
        } else {
            $securityFindings += "[WARN]  Monitoring not configured"
        }
        # Check firewall configuration
        if ($AllowedIPs.Count -gt 0) {
            $securityScore++
            $securityFindings += "[OK] Custom firewall rules configured"
        } else {
            $securityFindings += "[WARN]  Only Azure services allowed - configure specific IP rules"
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
        $costRecommendations = @()
    if ($Action.ToLower() -eq "create") {
        $costRecommendations += "Enable auto-pause for Spark pools to reduce costs during idle time"
        $costRecommendations += "Use serverless SQL pool for exploratory workloads"
        $costRecommendations += "Schedule SQL pool scaling based on usage patterns"
        $costRecommendations += "Monitor storage costs and implement lifecycle policies"
        $costRecommendations += "Use reserved capacity for predictable workloads"
    }
    # Final validation
        if ($Action.ToLower() -notin @("delete")) {
        $workspaceStatus = Invoke-AzureOperation -Operation {
            Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
        } -OperationName "Validate Workspace Status"
    }
    # Success summary
    Write-Host ""
    Write-Host "                      AZURE SYNAPSE ANALYTICS WORKSPACE READY"
    Write-Host ""
    if ($Action.ToLower() -eq "create") {
        Write-Host "Synapse Workspace Details:"
        Write-Host "    Workspace Name: $WorkspaceName"
        Write-Host "    Resource Group: $ResourceGroupName"
        Write-Host "    Location: $Location"
        Write-Host "    Workspace URL: https://$WorkspaceName.dev.azuresynapse.net"
        Write-Host "    SQL Admin: $SQLAdminUsername"
        Write-Host "    Storage Account: $StorageAccountName"
        Write-Host "    Status: $($workspaceStatus.ProvisioningState)"
        if ($SQLAdminPassword) {
            Write-Host ""
            Write-Host "    Username: $SQLAdminUsername"
            Write-Host "    Password: [SecureString - Store in Key Vault]"
            Write-Host "   [WARN]  Store these credentials securely in Azure Key Vault!"
        }
        Write-Host ""
        Write-Host "[LOCK] Security Assessment: $securityScore/$maxScore"
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding"
        }
        Write-Host ""
        Write-Host "Cost Optimization:"
        foreach ($recommendation in $costRecommendations) {
            Write-Host "   $recommendation"
        }
        Write-Host ""
        Write-Host "    Create SQL and Spark pools using CreateSQLPool/CreateSparkPool actions"
        Write-Host "    Import data using Azure Data Factory integration"
        Write-Host "    Configure Git integration for version control"
        Write-Host "    Set up monitoring alerts and dashboards"
        Write-Host "    Configure private endpoints for enhanced security"
    }
    Write-Host ""
    
} catch {
    
    Write-Host ""
    Write-Host "Troubleshooting Tips:"
    Write-Host "    Verify Synapse Analytics service availability in your region"
    Write-Host "    Check subscription quotas and limits"
    Write-Host "    Ensure proper permissions for resource creation"
    Write-Host "    Validate storage account configuration"
    Write-Host "    Check firewall rules and network connectivity"
    Write-Host ""
    throw
}

