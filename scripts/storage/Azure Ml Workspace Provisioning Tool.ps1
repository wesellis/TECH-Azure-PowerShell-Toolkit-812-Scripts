#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
    Azure Ml Workspace Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$KeyVaultName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ApplicationInsightsName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerRegistryName,
    [string]$Sku = "Basic"
)
Write-Output "Provisioning ML Workspace: $WorkspaceName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output "Location: $Location" "INFO"
Write-Output "SKU: $Sku" "INFO"
Write-Output " `nSetting up dependent resources..." "INFO"
if ($StorageAccountName) {
    [string]$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $StorageAccount) {
        Write-Output "Creating Storage Account: $StorageAccountName" "INFO"
    $params = @{
            ResourceGroupName = $ResourceGroupName
            SkuName = "Standard_LRS"
            Location = $Location
            Kind = "StorageV2" } Write-Output "Storage Account: $($StorageAccount.StorageAccountName)" "INFO"
            ErrorAction = "Stop"
            Name = $StorageAccountName
        }
    [string]$StorageAccount @params
}
if ($KeyVaultName) {
    [string]$KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ErrorAction SilentlyContinue
    if (-not $KeyVault) {
        Write-Output "Creating Key Vault: $KeyVaultName" "INFO"
    $params = @{
            Sku = "Standard" } Write-Output "Key Vault: $($KeyVault.VaultName)" "INFO"
            ErrorAction = "Stop"
            VaultName = $KeyVaultName
            ResourceGroupName = $ResourceGroupName
            Location = $Location
        }
    [string]$KeyVault @params
}
if ($ApplicationInsightsName) {
    [string]$AppInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $ApplicationInsightsName -ErrorAction SilentlyContinue
    if (-not $AppInsights) {
        Write-Output "Creating Application Insights: $ApplicationInsightsName" "INFO"
    $params = @{
            ErrorAction = "Stop"
            Kind = " web" } Write-Output "Application Insights: $($AppInsights.Name)" "INFO"
            ResourceGroupName = $ResourceGroupName
            Name = $ApplicationInsightsName
            Location = $Location
        }
    [string]$AppInsights @params
}
if ($ContainerRegistryName) {
    [string]$ContainerRegistry = Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ContainerRegistryName -ErrorAction SilentlyContinue
    if (-not $ContainerRegistry) {
        Write-Output "Creating Container Registry: $ContainerRegistryName" "INFO"
    $params = @{
            ResourceGroupName = $ResourceGroupName
            Sku = "Basic"
            Location = $Location
            ErrorAction = "Stop"
            EnableAdminUser = "} Write-Output "Container Registry: $($ContainerRegistry.Name)" "INFO"
            Name = $ContainerRegistryName
        }
    [string]$ContainerRegistry @params
}
Write-Output " `nCreating ML Workspace..." "INFO";
    $MLWorkspaceParams = @{
    ResourceGroupName = $ResourceGroupName
    Name = $WorkspaceName
    Location = $Location
    Sku = $Sku
}
if ($StorageAccount) {
    [string]$MLWorkspaceParams.StorageAccount = $StorageAccount.Id
}
if ($KeyVault) {
    [string]$MLWorkspaceParams.KeyVault = $KeyVault.ResourceId
}
if ($AppInsights) {
    [string]$MLWorkspaceParams.ApplicationInsights = $AppInsights.Id
}
if ($ContainerRegistry) {
    [string]$MLWorkspaceParams.ContainerRegistry = $ContainerRegistry.Id
}
    [string]$MLWorkspace = New-AzMLWorkspace -ErrorAction Stop @MLWorkspaceParams
Write-Output " `nML Workspace $WorkspaceName provisioned successfully" "INFO"
Write-Output "Workspace ID: $($MLWorkspace.Id)" "INFO"
Write-Output "Discovery URL: $($MLWorkspace.DiscoveryUrl)" "INFO"
Write-Output " `nWorkspace Components:" "INFO"
Write-Output "Storage Account: $($StorageAccount.StorageAccountName)" "INFO"
Write-Output "Key Vault: $($KeyVault.VaultName)" "INFO"
Write-Output "Application Insights: $($AppInsights.Name)" "INFO"
if ($ContainerRegistry) {
    Write-Output "Container Registry: $($ContainerRegistry.Name)" "INFO"
}
Write-Output " `nML Studio Access:" "INFO"
Write-Output "Portal URL: https://ml.azure.com/workspaces/$($MLWorkspace.WorkspaceId)/overview" "INFO"
Write-Output " `nNext Steps:" "INFO"
Write-Output " 1. Open Azure ML Studio in the browser" "INFO"
Write-Output " 2. Create compute instances for development" "INFO"
Write-Output " 3. Upload or connect to your datasets" "INFO"
Write-Output " 4. Create and train ML models" "INFO"
Write-Output " 5. Deploy models as web services" "INFO"
Write-Output " 6. Set up MLOps pipelines for automation" "INFO"
Write-Output " `nML Workspace Features:" "INFO"
Write-Output "   Jupyter notebooks and VS Code integration" "INFO"
Write-Output "   AutoML for automated machine learning" "INFO"
Write-Output "   Designer for drag-and-drop ML pipelines" "INFO"
Write-Output "   Model management and versioning" "INFO"
Write-Output "   Real-time and batch inference endpoints" "INFO"
Write-Output " `nML Workspace provisioning completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
