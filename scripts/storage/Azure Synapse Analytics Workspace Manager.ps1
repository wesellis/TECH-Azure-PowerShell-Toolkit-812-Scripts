#Requires -Version 7.4
#Requires -Modules Az.Storage
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Synapse Analytics Workspace Manager

.DESCRIPTION
    Azure automation for managing Synapse Analytics workspaces

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
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

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

Write-Host "Azure Synapse Analytics Workspace Manager" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Green
Write-Host "Workspace: $WorkspaceName" -ForegroundColor Green

try {
    # Verify Azure connection
    if (-not (Get-AzContext)) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }

    # Get resource group
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    Write-Host "Resource Group verified: $ResourceGroupName" -ForegroundColor Green

    switch ($Action.ToLower()) {
        "create" {
            Write-Host "Creating Synapse Analytics Workspace..." -ForegroundColor Green

            # Create storage account if not provided
            if (-not $StorageAccountName) {
                $StorageAccountName = ($WorkspaceName + "storage").ToLower() -replace '[^a-z0-9]', ''
                if ($StorageAccountName.Length -gt 24) {
                    $StorageAccountName = $StorageAccountName.Substring(0, 24)
                }
            }

            Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Green

            # Check/Create storage account
            $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
            if (-not $StorageAccount) {
                Write-Host "Creating storage account..." -ForegroundColor Yellow
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
                $StorageAccount = New-AzStorageAccount @StorageParams
            }

            # Create file system
            $ctx = $StorageAccount.Context
            $existing = Get-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName -ErrorAction SilentlyContinue
            if (-not $existing) {
                Write-Host "Creating file system..." -ForegroundColor Yellow
                New-AzDataLakeGen2FileSystem -Context $ctx -Name $FileSystemName | Out-Null
            }

            # Generate password if not provided
            if (-not $SQLAdminPassword) {
                $PasswordText = -join ((65..90) + (97..122) + (48..57) + @(33,35,36,37,38,42,43,45,61,63,64) | Get-Random -Count 16 | ForEach-Object {[char]$_})
                $SQLAdminPassword = ConvertTo-SecureString -String $PasswordText -AsPlainText -Force
                Write-Host "Generated SQL Admin password (store securely!): $PasswordText" -ForegroundColor Yellow
            }

            # Create workspace
            Write-Host "Creating Synapse workspace..." -ForegroundColor Yellow
            $WorkspaceParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $WorkspaceName
                Location = $Location
                DefaultDataLakeStorageAccountName = $StorageAccountName
                DefaultDataLakeStorageFilesystem = $FileSystemName
                SqlAdministratorLoginCredential = (New-Object System.Management.Automation.PSCredential($SQLAdminUsername, $SQLAdminPassword))
            }

            if ($EnableManagedVNet) {
                $WorkspaceParams['ManagedVirtualNetwork'] = $true
            }
            if ($EnableDataExfiltrationProtection) {
                $WorkspaceParams['PreventDataExfiltration'] = $true
            }

            $workspace = New-AzSynapseWorkspace @WorkspaceParams
            Write-Host "Workspace created successfully!" -ForegroundColor Green

            # Configure firewall
            Write-Host "Configuring firewall rules..." -ForegroundColor Yellow
            New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name "AllowAllWindowsAzureIps" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0" | Out-Null

            if ($AllowedIPs.Count -gt 0) {
                foreach ($ip in $AllowedIPs) {
                    $RuleName = "CustomRule-$($ip -replace '\.', '-')"
                    New-AzSynapseFirewallRule -WorkspaceName $WorkspaceName -Name $RuleName -StartIpAddress $ip -EndIpAddress $ip | Out-Null
                    Write-Host "Added firewall rule for: $ip" -ForegroundColor Green
                }
            }

            Write-Host "" -ForegroundColor Green
            Write-Host "Synapse Workspace Details:" -ForegroundColor Green
            Write-Host "  Workspace Name: $WorkspaceName" -ForegroundColor Green
            Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor Green
            Write-Host "  Location: $Location" -ForegroundColor Green
            Write-Host "  Workspace URL: https://$WorkspaceName.dev.azuresynapse.net" -ForegroundColor Green
            Write-Host "  SQL Admin: $SQLAdminUsername" -ForegroundColor Green
            Write-Host "  Storage Account: $StorageAccountName" -ForegroundColor Green
        }

        "getinfo" {
            $workspace = Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
            $SqlPools = Get-AzSynapseSqlPool -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
            $SparkPools = Get-AzSynapseSparkPool -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue

            Write-Host "" -ForegroundColor Green
            Write-Host "Synapse Workspace Information" -ForegroundColor Green
            Write-Host "  Workspace Name: $($workspace.Name)" -ForegroundColor Green
            Write-Host "  Location: $($workspace.Location)" -ForegroundColor Green
            Write-Host "  Workspace URL: $($workspace.WebUrl)" -ForegroundColor Green
            Write-Host "  Provisioning State: $($workspace.ProvisioningState)" -ForegroundColor Green

            if ($SqlPools) {
                Write-Host "" -ForegroundColor Green
                Write-Host "SQL Pools:" -ForegroundColor Green
                foreach ($pool in $SqlPools) {
                    Write-Host "  $($pool.Name) - $($pool.Sku.Name) - $($pool.Status)" -ForegroundColor Green
                }
            }

            if ($SparkPools) {
                Write-Host "" -ForegroundColor Green
                Write-Host "Spark Pools:" -ForegroundColor Green
                foreach ($pool in $SparkPools) {
                    Write-Host "  $($pool.Name) - $($pool.NodeSize) - Nodes: $($pool.NodeCount)" -ForegroundColor Green
                }
            }
        }

        "createsqlpool" {
            Write-Host "Creating SQL Pool: $SQLPoolName" -ForegroundColor Yellow
            $SqlPoolParams = @{
                WorkspaceName = $WorkspaceName
                Name = $SQLPoolName
                PerformanceLevel = $SQLPoolSKU
            }
            New-AzSynapseSqlPool @SqlPoolParams
            Write-Host "SQL Pool created successfully!" -ForegroundColor Green
        }

        "createsparkpool" {
            Write-Host "Creating Spark Pool: $SparkPoolName" -ForegroundColor Yellow
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
            New-AzSynapseSparkPool @SparkPoolParams
            Write-Host "Spark Pool created successfully!" -ForegroundColor Green
        }

        "delete" {
            $confirmation = Read-Host "Are you sure you want to delete the Synapse workspace '$WorkspaceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                Write-Host "Deletion cancelled" -ForegroundColor Yellow
                return
            }

            Write-Host "Deleting Synapse workspace..." -ForegroundColor Yellow
            Remove-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Force
            Write-Host "Synapse workspace deleted successfully" -ForegroundColor Green
        }

        default {
            Write-Host "Action not implemented: $Action" -ForegroundColor Yellow
        }
    }

} catch {
    Write-Error "Synapse operation failed: $($_.Exception.Message)"
    Write-Host "" -ForegroundColor Red
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "  - Verify Synapse Analytics service availability in your region" -ForegroundColor Yellow
    Write-Host "  - Check subscription quotas and limits" -ForegroundColor Yellow
    Write-Host "  - Ensure proper permissions for resource creation" -ForegroundColor Yellow
    Write-Host "  - Validate storage account configuration" -ForegroundColor Yellow
    throw
}