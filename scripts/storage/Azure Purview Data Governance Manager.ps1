#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Purview Data Governance Manager

.DESCRIPTION
    Azure automation for managing Purview data governance

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

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

Write-Host "Azure Purview Data Governance Manager" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Green

try {
    if (-not (Get-AzContext)) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }

    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop

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
            Write-Host "Creating Purview Account..." -ForegroundColor Green

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

            $PurviewAccount = New-AzPurviewAccount @PurviewParams -ErrorAction Stop

            Write-Host "Purview Account created successfully" -ForegroundColor Green
            Write-Host "Account Name: $($PurviewAccount.Name)" -ForegroundColor Green
            Write-Host "Atlas Endpoint: $($PurviewAccount.AtlasEndpoint)" -ForegroundColor Green
        }

        "getinfo" {
            $PurviewAccount = Get-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName

            Write-Host "`nPurview Account Information" -ForegroundColor Green
            Write-Host "  Account Name: $($PurviewAccount.Name)" -ForegroundColor Green
            Write-Host "  Location: $($PurviewAccount.Location)" -ForegroundColor Green
            Write-Host "  Provisioning State: $($PurviewAccount.ProvisioningState)" -ForegroundColor Green
            Write-Host "  Public Network Access: $($PurviewAccount.PublicNetworkAccess)" -ForegroundColor Green
        }

        "delete" {
            $confirmation = Read-Host "Are you sure you want to delete the Purview account '$PurviewAccountName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                Write-Host "Deletion cancelled" -ForegroundColor Yellow
                return
            }

            Remove-AzPurviewAccount -ResourceGroupName $ResourceGroupName -Name $PurviewAccountName -Force
            Write-Host "Purview Account deleted successfully" -ForegroundColor Green
        }

        default {
            Write-Host "Action not implemented: $Action" -ForegroundColor Yellow
        }
    }

} catch {
    Write-Error "Purview operation failed: $($_.Exception.Message)"
    throw
}