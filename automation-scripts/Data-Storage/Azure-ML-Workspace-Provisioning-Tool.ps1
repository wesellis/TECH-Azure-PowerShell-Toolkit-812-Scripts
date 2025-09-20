#Requires -Version 7.0
#Requires -Modules Az.Storage
#Requires -Modules Az.KeyVault

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$WorkspaceName,
    [string]$Location,
    [string]$StorageAccountName,
    [string]$KeyVaultName,
    [string]$ApplicationInsightsName,
    [string]$ContainerRegistryName,
    [string]$Sku = "Basic"
)
Write-Host "Provisioning ML Workspace: $WorkspaceName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $Sku"
# Create or get required resources
Write-Host "`nSetting up dependent resources..."
# Storage Account
if ($StorageAccountName) {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $StorageAccount) {
        Write-Host "Creating Storage Account: $StorageAccountName"
        $params = @{
            ResourceGroupName = $ResourceGroupName
            SkuName = "Standard_LRS"
            Location = $Location
            Kind = "StorageV2" } Write-Host "Storage Account: $($StorageAccount.StorageAccountName)"
            ErrorAction = "Stop"
            Name = $StorageAccountName
        }
        $StorageAccount @params
}
# Key Vault
if ($KeyVaultName) {
    $KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ErrorAction SilentlyContinue
    if (-not $KeyVault) {
        Write-Host "Creating Key Vault: $KeyVaultName"
        $params = @{
            Sku = "Standard" } Write-Host "Key Vault: $($KeyVault.VaultName)"
            ErrorAction = "Stop"
            VaultName = $KeyVaultName
            ResourceGroupName = $ResourceGroupName
            Location = $Location
        }
        $KeyVault @params
}
# Application Insights
if ($ApplicationInsightsName) {
    $AppInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $ApplicationInsightsName -ErrorAction SilentlyContinue
    if (-not $AppInsights) {
        Write-Host "Creating Application Insights: $ApplicationInsightsName"
        $params = @{
            ErrorAction = "Stop"
            Kind = "web" } Write-Host "Application Insights: $($AppInsights.Name)"
            ResourceGroupName = $ResourceGroupName
            Name = $ApplicationInsightsName
            Location = $Location
        }
        $AppInsights @params
}
# Container Registry (optional)
if ($ContainerRegistryName) {
    $ContainerRegistry = Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ContainerRegistryName -ErrorAction SilentlyContinue
    if (-not $ContainerRegistry) {
        Write-Host "Creating Container Registry: $ContainerRegistryName"
        $params = @{
            ResourceGroupName = $ResourceGroupName
            Sku = "Basic"
            Location = $Location
            ErrorAction = "Stop"
            EnableAdminUser = "} Write-Host "Container Registry: $($ContainerRegistry.Name)"
            Name = $ContainerRegistryName
        }
        $ContainerRegistry @params
}
# Create the ML Workspace
Write-Host "`nCreating ML Workspace..."
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
Write-Host "`nML Workspace $WorkspaceName provisioned successfully"
Write-Host "Workspace ID: $($MLWorkspace.Id)"
Write-Host "Discovery URL: $($MLWorkspace.DiscoveryUrl)"
Write-Host "`nWorkspace Components:"
Write-Host "Storage Account: $($StorageAccount.StorageAccountName)"
Write-Host "Key Vault: $($KeyVault.VaultName)"
Write-Host "Application Insights: $($AppInsights.Name)"
if ($ContainerRegistry) {
    Write-Host "Container Registry: $($ContainerRegistry.Name)"
}
Write-Host "`nML Studio Access:"
Write-Host "Portal URL: https://ml.azure.com/workspaces/$($MLWorkspace.WorkspaceId)/overview"
Write-Host "`nNext Steps:"
Write-Host "1. Open Azure ML Studio in the browser"
Write-Host "2. Create compute instances for development"
Write-Host "3. Upload or connect to your datasets"
Write-Host "4. Create and train ML models"
Write-Host "5. Deploy models as web services"
Write-Host "6. Set up MLOps pipelines for automation"
Write-Host "`nML Workspace Features:"
Write-Host "   Jupyter notebooks and VS Code integration"
Write-Host "   AutoML for automated machine learning"
Write-Host "   Designer for drag-and-drop ML pipelines"
Write-Host "   Model management and versioning"
Write-Host "   Real-time and batch inference endpoints"
Write-Host "`nML Workspace provisioning completed at $(Get-Date)"

