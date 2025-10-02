#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$WorkspaceName,
    [string]$Location,
    [string]$StorageAccountName,
    [string]$KeyVaultName,
    [string]$ApplicationInsightsName,
    [string]$ContainerRegistryName,
    [string]$Sku = "Basic"
)
Write-Output "Provisioning ML Workspace: $WorkspaceName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "SKU: $Sku"
Write-Output "`nSetting up dependent resources..."
if ($StorageAccountName) {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $StorageAccount) {
        Write-Output "Creating Storage Account: $StorageAccountName"
        $params = @{
            ResourceGroupName = $ResourceGroupName
            SkuName = "Standard_LRS"
            Location = $Location
            Kind = "StorageV2" } Write-Output "Storage Account: $($StorageAccount.StorageAccountName)"
            ErrorAction = "Stop"
            Name = $StorageAccountName
        }
        $StorageAccount @params
}
if ($KeyVaultName) {
    $KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ErrorAction SilentlyContinue
    if (-not $KeyVault) {
        Write-Output "Creating Key Vault: $KeyVaultName"
        $params = @{
            Sku = "Standard" } Write-Output "Key Vault: $($KeyVault.VaultName)"
            ErrorAction = "Stop"
            VaultName = $KeyVaultName
            ResourceGroupName = $ResourceGroupName
            Location = $Location
        }
        $KeyVault @params
}
if ($ApplicationInsightsName) {
    $AppInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $ApplicationInsightsName -ErrorAction SilentlyContinue
    if (-not $AppInsights) {
        Write-Output "Creating Application Insights: $ApplicationInsightsName"
        $params = @{
            ErrorAction = "Stop"
            Kind = "web" } Write-Output "Application Insights: $($AppInsights.Name)"
            ResourceGroupName = $ResourceGroupName
            Name = $ApplicationInsightsName
            Location = $Location
        }
        $AppInsights @params
}
if ($ContainerRegistryName) {
    $ContainerRegistry = Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ContainerRegistryName -ErrorAction SilentlyContinue
    if (-not $ContainerRegistry) {
        Write-Output "Creating Container Registry: $ContainerRegistryName"
        $params = @{
            ResourceGroupName = $ResourceGroupName
            Sku = "Basic"
            Location = $Location
            ErrorAction = "Stop"
            EnableAdminUser = "} Write-Output "Container Registry: $($ContainerRegistry.Name)"
            Name = $ContainerRegistryName
        }
        $ContainerRegistry @params
}
Write-Output "`nCreating ML Workspace..."
$MLWorkspaceParams = @{
    ResourceGroupName = $ResourceGroupName
    Name = $WorkspaceName
    Location = $Location
    Sku = $Sku
}
if ($StorageAccount) {
    $MLWorkspaceParams.StorageAccount = $StorageAccount.Id
}
if ($KeyVault) {
    $MLWorkspaceParams.KeyVault = $KeyVault.ResourceId
}
if ($AppInsights) {
    $MLWorkspaceParams.ApplicationInsights = $AppInsights.Id
}
if ($ContainerRegistry) {
    $MLWorkspaceParams.ContainerRegistry = $ContainerRegistry.Id
}
$MLWorkspace = New-AzMLWorkspace -ErrorAction Stop @MLWorkspaceParams
Write-Output "`nML Workspace $WorkspaceName provisioned successfully"
Write-Output "Workspace ID: $($MLWorkspace.Id)"
Write-Output "Discovery URL: $($MLWorkspace.DiscoveryUrl)"
Write-Output "`nWorkspace Components:"
Write-Output "Storage Account: $($StorageAccount.StorageAccountName)"
Write-Output "Key Vault: $($KeyVault.VaultName)"
Write-Output "Application Insights: $($AppInsights.Name)"
if ($ContainerRegistry) {
    Write-Output "Container Registry: $($ContainerRegistry.Name)"
}
Write-Output "`nML Studio Access:"
Write-Output "Portal URL: https://ml.azure.com/workspaces/$($MLWorkspace.WorkspaceId)/overview"
Write-Output "`nNext Steps:"
Write-Output "1. Open Azure ML Studio in the browser"
Write-Output "2. Create compute instances for development"
Write-Output "3. Upload or connect to your datasets"
Write-Output "4. Create and train ML models"
Write-Output "5. Deploy models as web services"
Write-Output "6. Set up MLOps pipelines for automation"
Write-Output "`nML Workspace Features:"
Write-Output "   Jupyter notebooks and VS Code integration"
Write-Output "   AutoML for automated machine learning"
Write-Output "   Designer for drag-and-drop ML pipelines"
Write-Output "   Model management and versioning"
Write-Output "   Real-time and batch inference endpoints"
Write-Output "`nML Workspace provisioning completed at $(Get-Date)"



