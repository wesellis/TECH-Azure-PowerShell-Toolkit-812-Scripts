#Requires -Version 7.4
#Requires -Modules Az.Storage
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
        if (-not (Get-AzContext)) { Connect-AzAccount }
        $ResourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    switch ($Action.ToLower()) {
        "create" {
                if (-not $StorageAccountName) {
                $StorageAccountName = ($WorkspaceName + "storage").ToLower() -replace '[^a-z0-9]', ''
                if ($StorageAccountName.Length -gt 24) {
                    $StorageAccountName = $StorageAccountName.Substring(0, 24)
                }
            }
            $StorageAccount = Invoke-AzureOperation -Operation {
                $existing = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
                if ($existing) {

                    return $existing
                } else {

                    $StorageParams = @{
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
            $ctx = $StorageAccount.Context
            $null = Invoke-AzureOperation -Operation {
                $existing = Get-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName -ErrorAction SilentlyContinue
                if (-not $existing) {
                    New-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName

                } else {

                    return $existing
                }
            } -OperationName "Create File System"

            if (-not $SQLAdminPassword) {
                $PasswordText = -join ((65..90) + (97..122) + (48..57) + @(33,35,36,37,38,42,43,45,61,63,64) | Get-Random -Count 16 | ForEach-Object {[char]$_})
                $SQLAdminPassword = Read-Host -Prompt "Enter secure value" -AsSecureString

            }
                $WorkspaceParams = @{
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

            Invoke-AzureOperation -Operation {
                New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name "AllowAllWindowsAzureIps" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0"
            } -OperationName "Create Azure Services Firewall Rule"
            if ($AllowedIPs.Count -gt 0) {
                foreach ($ip in $AllowedIPs) {
                    $RuleName = "CustomRule-$($ip -replace '\.', '-')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name $RuleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName "Create Custom IP Firewall Rule"
                }

            }
        }
        "createsqlpool" {
                $SqlPoolParams = @{
                WorkspaceName = $WorkspaceName
                Name = $SQLPoolName
                PerformanceLevel = $SQLPoolSKU
            }
            $null = Invoke-AzureOperation -Operation {
                New-AzSynapseSqlPool -ErrorAction Stop @sqlPoolParams
            } -OperationName "Create SQL Pool"

        }
        "createsparkpool" {
                $SparkPoolParams = @{
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
                $ExistingRules = Invoke-AzureOperation -Operation {
                Get-AzSynapseFirewallRule -WorkspaceName $WorkspaceName
            } -OperationName "Get Firewall Rules"
            Write-Output ""
            foreach ($rule in $ExistingRules) {
                Write-Output " $($rule.Name): $($rule.StartIpAddress) - $($rule.EndIpAddress)"
            }
            if ($AllowedIPs.Count -gt 0) {

                foreach ($ip in $AllowedIPs) {
                    $RuleName = "CustomRule-$($ip -replace '\.', '-')-$(Get-Date -Format 'yyyyMMdd')"
                    Invoke-AzureOperation -Operation {
                        New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name $RuleName -StartIpAddress $ip -EndIpAddress $ip
                    } -OperationName "Add Firewall Rule"

                }
            }
        }
        "getinfo" {
                $workspace = Invoke-AzureOperation -Operation {
                Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
            } -OperationName "Get Workspace Info"
            $SqlPools = Invoke-AzureOperation -Operation {
                Get-AzSynapseSqlPool -WorkspaceName $WorkspaceName
            } -OperationName "Get SQL Pools"
            $SparkPools = Invoke-AzureOperation -Operation {
                Get-AzSynapseSparkPool -WorkspaceName $WorkspaceName
            } -OperationName "Get Spark Pools"
            Write-Output ""
            Write-Output "Synapse Workspace Information"
            Write-Output "Workspace Name: $($workspace.Name)"
            Write-Output "Location: $($workspace.Location)"
            Write-Output "Workspace URL: $($workspace.WebUrl)"
            Write-Output "SQL Endpoint: $($workspace.SqlAdministratorLogin)"
            Write-Output "Provisioning State: $($workspace.ProvisioningState)"
            if ($SqlPools.Count -gt 0) {
                Write-Output ""
                Write-Output "SQL Pools:"
                foreach ($pool in $SqlPools) {
                    Write-Output " $($pool.Name) - $($pool.Sku.Name) - $($pool.Status)"
                }
            }
            if ($SparkPools.Count -gt 0) {
                Write-Output ""
                Write-Output "[!] Spark Pools:"
                foreach ($pool in $SparkPools) {
                    Write-Output " $($pool.Name) - $($pool.NodeSize) - Nodes: $($pool.NodeCount)"
                }
            }
        }
        "delete" {
                $confirmation = Read-Host "Are you sure you want to delete the Synapse workspace '$WorkspaceName' and all its resources? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {

                return
            }
            $SqlPools = Get-AzSynapseSqlPool -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
            foreach ($pool in $SqlPools) {

                if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
            }
            $SparkPools = Get-AzSynapseSparkPool -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
            foreach ($pool in $SparkPools) {

                if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
            }
            Invoke-AzureOperation -Operation {
                if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
            } -OperationName "Delete Synapse Workspace"

        }
    }
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
            $DiagnosticSettings = Invoke-AzureOperation -Operation {
            $LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($LogAnalyticsWorkspace) {
                $ResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Synapse/workspaces/$WorkspaceName"
                $DiagnosticParams = @{
                    ResourceId = $ResourceId
                    Name = "$WorkspaceName-diagnostics"
                    WorkspaceId = $LogAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("SynapseRbacOperations", "GatewayApiRequests", "BuiltinSqlReqsEnded", "IntegrationPipelineRuns", "IntegrationActivityRuns", "IntegrationTriggerRuns")
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
        $SecurityScore = 0
    $MaxScore = 6
    $SecurityFindings = @()
    if ($Action.ToLower() -eq "create") {
        if ($EnableManagedVNet) {
            $SecurityScore++
            $SecurityFindings += "[OK] Managed virtual network enabled"
        } else {
            $SecurityFindings += "[WARN]  Managed VNet not enabled - consider for enhanced security"
        }
        if ($EnableDataExfiltrationProtection) {
            $SecurityScore++
            $SecurityFindings += "[OK] Data exfiltration protection enabled"
        } else {
            $SecurityFindings += "[WARN]  Data exfiltration protection disabled"
        }
        if ($EnableMonitoring) {
            $SecurityScore++
            $SecurityFindings += "[OK] Monitoring enabled"
        } else {
            $SecurityFindings += "[WARN]  Monitoring not configured"
        }
        if ($AllowedIPs.Count -gt 0) {
            $SecurityScore++
            $SecurityFindings += "[OK] Custom firewall rules configured"
        } else {
            $SecurityFindings += "[WARN]  Only Azure services allowed - configure specific IP rules"
        }
        if ($StorageAccount.EnableHttpsTrafficOnly) {
            $SecurityScore++
            $SecurityFindings += "[OK] HTTPS-only traffic enforced on storage"
        }
        if ($Location -in @("East US", "West Europe", "Southeast Asia")) {
            $SecurityScore++
            $SecurityFindings += "[OK] Deployed in compliant region"
        }
    }
        $CostRecommendations = @()
    if ($Action.ToLower() -eq "create") {
        $CostRecommendations += "Enable auto-pause for Spark pools to reduce costs during idle time"
        $CostRecommendations += "Use serverless SQL pool for exploratory workloads"
        $CostRecommendations += "Schedule SQL pool scaling based on usage patterns"
        $CostRecommendations += "Monitor storage costs and implement lifecycle policies"
        $CostRecommendations += "Use reserved capacity for predictable workloads"
    }
        if ($Action.ToLower() -notin @("delete")) {
        $WorkspaceStatus = Invoke-AzureOperation -Operation {
            Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
        } -OperationName "Validate Workspace Status"
    }
    Write-Output ""
    Write-Output "                      AZURE SYNAPSE ANALYTICS WORKSPACE READY"
    Write-Output ""
    if ($Action.ToLower() -eq "create") {
        Write-Output "Synapse Workspace Details:"
        Write-Output "    Workspace Name: $WorkspaceName"
        Write-Output "    Resource Group: $ResourceGroupName"
        Write-Output "    Location: $Location"
        Write-Output "    Workspace URL: https://$WorkspaceName.dev.azuresynapse.net"
        Write-Output "    SQL Admin: $SQLAdminUsername"
        Write-Output "    Storage Account: $StorageAccountName"
        Write-Output "    Status: $($WorkspaceStatus.ProvisioningState)"
        if ($SQLAdminPassword) {
            Write-Output ""
            Write-Output "    Username: $SQLAdminUsername"
            Write-Output "    Password: [SecureString - Store in Key Vault]"
            Write-Output "   [WARN]  Store these credentials securely in Azure Key Vault!"
        }
        Write-Output ""
        Write-Output "[LOCK] Security Assessment: $SecurityScore/$MaxScore"
        foreach ($finding in $SecurityFindings) {
            Write-Output "   $finding"
        }
        Write-Output ""
        Write-Output "Cost Optimization:"
        foreach ($recommendation in $CostRecommendations) {
            Write-Output "   $recommendation"
        }
        Write-Output ""
        Write-Output "    Create SQL and Spark pools using CreateSQLPool/CreateSparkPool actions"
        Write-Output "    Import data using Azure Data Factory integration"
        Write-Output "    Configure Git integration for version control"
        Write-Output "    Set up monitoring alerts and dashboards"
        Write-Output "    Configure private endpoints for enhanced security"
    }
    Write-Output ""

} catch {

    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify Synapse Analytics service availability in your region"
    Write-Output "    Check subscription quotas and limits"
    Write-Output "    Ensure proper permissions for resource creation"
    Write-Output "    Validate storage account configuration"
    Write-Output "    Check firewall rules and network connectivity"
    Write-Output ""
    throw`n}
