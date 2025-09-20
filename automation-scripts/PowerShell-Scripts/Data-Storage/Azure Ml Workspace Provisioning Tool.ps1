<#
.SYNOPSIS
    Azure Ml Workspace Provisioning Tool

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
Write-Host "Provisioning ML Workspace: $WorkspaceName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host "Location: $Location" "INFO"
Write-Host "SKU: $Sku" "INFO"
Write-Host " `nSetting up dependent resources..." "INFO"
if ($StorageAccountName) {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $StorageAccount) {
        Write-Host "Creating Storage Account: $StorageAccountName" "INFO"
        $params = @{
            ResourceGroupName = $ResourceGroupName
            SkuName = "Standard_LRS"
            Location = $Location
            Kind = "StorageV2" } Write-Host "Storage Account: $($StorageAccount.StorageAccountName)" "INFO"
            ErrorAction = "Stop"
            Name = $StorageAccountName
        }
        $StorageAccount @params
}
if ($KeyVaultName) {
    $KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ErrorAction SilentlyContinue
    if (-not $KeyVault) {
        Write-Host "Creating Key Vault: $KeyVaultName" "INFO"
        $params = @{
            Sku = "Standard" } Write-Host "Key Vault: $($KeyVault.VaultName)" "INFO"
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
        Write-Host "Creating Application Insights: $ApplicationInsightsName" "INFO"
        $params = @{
            ErrorAction = "Stop"
            Kind = " web" } Write-Host "Application Insights: $($AppInsights.Name)" "INFO"
            ResourceGroupName = $ResourceGroupName
            Name = $ApplicationInsightsName
            Location = $Location
        }
        $AppInsights @params
}
if ($ContainerRegistryName) {
    $ContainerRegistry = Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ContainerRegistryName -ErrorAction SilentlyContinue
    if (-not $ContainerRegistry) {
        Write-Host "Creating Container Registry: $ContainerRegistryName" "INFO"
        $params = @{
            ResourceGroupName = $ResourceGroupName
            Sku = "Basic"
            Location = $Location
            ErrorAction = "Stop"
            EnableAdminUser = "} Write-Host "Container Registry: $($ContainerRegistry.Name)" "INFO"
            Name = $ContainerRegistryName
        }
        $ContainerRegistry @params
}
Write-Host " `nCreating ML Workspace..." "INFO";
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
Write-Host " `nML Workspace $WorkspaceName provisioned successfully" "INFO"
Write-Host "Workspace ID: $($MLWorkspace.Id)" "INFO"
Write-Host "Discovery URL: $($MLWorkspace.DiscoveryUrl)" "INFO"
Write-Host " `nWorkspace Components:" "INFO"
Write-Host "Storage Account: $($StorageAccount.StorageAccountName)" "INFO"
Write-Host "Key Vault: $($KeyVault.VaultName)" "INFO"
Write-Host "Application Insights: $($AppInsights.Name)" "INFO"
if ($ContainerRegistry) {
    Write-Host "Container Registry: $($ContainerRegistry.Name)" "INFO"
}
Write-Host " `nML Studio Access:" "INFO"
Write-Host "Portal URL: https://ml.azure.com/workspaces/$($MLWorkspace.WorkspaceId)/overview" "INFO"
Write-Host " `nNext Steps:" "INFO"
Write-Host " 1. Open Azure ML Studio in the browser" "INFO"
Write-Host " 2. Create compute instances for development" "INFO"
Write-Host " 3. Upload or connect to your datasets" "INFO"
Write-Host " 4. Create and train ML models" "INFO"
Write-Host " 5. Deploy models as web services" "INFO"
Write-Host " 6. Set up MLOps pipelines for automation" "INFO"
Write-Host " `nML Workspace Features:" "INFO"
Write-Host "   Jupyter notebooks and VS Code integration" "INFO"
Write-Host "   AutoML for automated machine learning" "INFO"
Write-Host "   Designer for drag-and-drop ML pipelines" "INFO"
Write-Host "   Model management and versioning" "INFO"
Write-Host "   Real-time and batch inference endpoints" "INFO"
Write-Host " `nML Workspace provisioning completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n