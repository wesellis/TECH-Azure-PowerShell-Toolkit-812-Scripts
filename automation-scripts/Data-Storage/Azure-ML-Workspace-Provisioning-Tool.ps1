# ============================================================================
# Script Name: Azure Machine Learning Workspace Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Machine Learning workspaces for AI and ML development
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$WorkspaceName,
    [string]$Location,
    [string]$StorageAccountName,
    [string]$KeyVaultName,
    [string]$ApplicationInsightsName,
    [string]$ContainerRegistryName,
    [string]$Sku = "Basic"
)

Write-Information "Provisioning ML Workspace: $WorkspaceName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $Sku"

# Create or get required resources
Write-Information "`nSetting up dependent resources..."

# Storage Account
if ($StorageAccountName) {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $StorageAccount) {
        Write-Information "Creating Storage Account: $StorageAccountName"
        $StorageAccount = New-AzStorageAccount -ErrorAction Stop `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -Location $Location `
            -SkuName "Standard_LRS" `
            -Kind "StorageV2"
    }
    Write-Information "Storage Account: $($StorageAccount.StorageAccountName)"
}

# Key Vault
if ($KeyVaultName) {
    $KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ErrorAction SilentlyContinue
    if (-not $KeyVault) {
        Write-Information "Creating Key Vault: $KeyVaultName"
        $KeyVault = New-AzKeyVault -ErrorAction Stop `
            -ResourceGroupName $ResourceGroupName `
            -VaultName $KeyVaultName `
            -Location $Location `
            -Sku "Standard"
    }
    Write-Information "Key Vault: $($KeyVault.VaultName)"
}

# Application Insights
if ($ApplicationInsightsName) {
    $AppInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $ApplicationInsightsName -ErrorAction SilentlyContinue
    if (-not $AppInsights) {
        Write-Information "Creating Application Insights: $ApplicationInsightsName"
        $AppInsights = New-AzApplicationInsights -ErrorAction Stop `
            -ResourceGroupName $ResourceGroupName `
            -Name $ApplicationInsightsName `
            -Location $Location `
            -Kind "web"
    }
    Write-Information "Application Insights: $($AppInsights.Name)"
}

# Container Registry (optional)
if ($ContainerRegistryName) {
    $ContainerRegistry = Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ContainerRegistryName -ErrorAction SilentlyContinue
    if (-not $ContainerRegistry) {
        Write-Information "Creating Container Registry: $ContainerRegistryName"
        $ContainerRegistry = New-AzContainerRegistry -ErrorAction Stop `
            -ResourceGroupName $ResourceGroupName `
            -Name $ContainerRegistryName `
            -Location $Location `
            -Sku "Basic" `
            -EnableAdminUser
    }
    Write-Information "Container Registry: $($ContainerRegistry.Name)"
}

# Create the ML Workspace
Write-Information "`nCreating ML Workspace..."
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

Write-Information "`nML Workspace $WorkspaceName provisioned successfully"
Write-Information "Workspace ID: $($MLWorkspace.Id)"
Write-Information "Discovery URL: $($MLWorkspace.DiscoveryUrl)"

Write-Information "`nWorkspace Components:"
Write-Information "  Storage Account: $($StorageAccount.StorageAccountName)"
Write-Information "  Key Vault: $($KeyVault.VaultName)"
Write-Information "  Application Insights: $($AppInsights.Name)"
if ($ContainerRegistry) {
    Write-Information "  Container Registry: $($ContainerRegistry.Name)"
}

Write-Information "`nML Studio Access:"
Write-Information "Portal URL: https://ml.azure.com/workspaces/$($MLWorkspace.WorkspaceId)/overview"

Write-Information "`nNext Steps:"
Write-Information "1. Open Azure ML Studio in the browser"
Write-Information "2. Create compute instances for development"
Write-Information "3. Upload or connect to your datasets"
Write-Information "4. Create and train ML models"
Write-Information "5. Deploy models as web services"
Write-Information "6. Set up MLOps pipelines for automation"

Write-Information "`nML Workspace Features:"
Write-Information "  • Jupyter notebooks and VS Code integration"
Write-Information "  • AutoML for automated machine learning"
Write-Information "  • Designer for drag-and-drop ML pipelines"
Write-Information "  • Model management and versioning"
Write-Information "  • Real-time and batch inference endpoints"

Write-Information "`nML Workspace provisioning completed at $(Get-Date)"
