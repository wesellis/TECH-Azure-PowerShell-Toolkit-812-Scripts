<#
.SYNOPSIS
    Azure Ml Workspace Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Ml Workspace Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEWorkspaceName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEStorageAccountName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEKeyVaultName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEApplicationInsightsName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEContainerRegistryName,
    [string]$WESku = " Basic"
)

Write-WELog " Provisioning ML Workspace: $WEWorkspaceName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " SKU: $WESku" " INFO"


Write-WELog " `nSetting up dependent resources..." " INFO"


if ($WEStorageAccountName) {
    $WEStorageAccount = Get-AzStorageAccount -ResourceGroupName $WEResourceGroupName -Name $WEStorageAccountName -ErrorAction SilentlyContinue
    if (-not $WEStorageAccount) {
        Write-WELog " Creating Storage Account: $WEStorageAccountName" " INFO"
        $WEStorageAccount = New-AzStorageAccount `
            -ResourceGroupName $WEResourceGroupName `
            -Name $WEStorageAccountName `
            -Location $WELocation `
            -SkuName " Standard_LRS" `
            -Kind " StorageV2"
    }
    Write-WELog " Storage Account: $($WEStorageAccount.StorageAccountName)" " INFO"
}


if ($WEKeyVaultName) {
    $WEKeyVault = Get-AzKeyVault -ResourceGroupName $WEResourceGroupName -VaultName $WEKeyVaultName -ErrorAction SilentlyContinue
    if (-not $WEKeyVault) {
        Write-WELog " Creating Key Vault: $WEKeyVaultName" " INFO"
        $WEKeyVault = New-AzKeyVault `
            -ResourceGroupName $WEResourceGroupName `
            -VaultName $WEKeyVaultName `
            -Location $WELocation `
            -Sku " Standard"
    }
    Write-WELog " Key Vault: $($WEKeyVault.VaultName)" " INFO"
}


if ($WEApplicationInsightsName) {
    $WEAppInsights = Get-AzApplicationInsights -ResourceGroupName $WEResourceGroupName -Name $WEApplicationInsightsName -ErrorAction SilentlyContinue
    if (-not $WEAppInsights) {
        Write-WELog " Creating Application Insights: $WEApplicationInsightsName" " INFO"
        $WEAppInsights = New-AzApplicationInsights `
            -ResourceGroupName $WEResourceGroupName `
            -Name $WEApplicationInsightsName `
            -Location $WELocation `
            -Kind " web"
    }
    Write-WELog " Application Insights: $($WEAppInsights.Name)" " INFO"
}


if ($WEContainerRegistryName) {
    $WEContainerRegistry = Get-AzContainerRegistry -ResourceGroupName $WEResourceGroupName -Name $WEContainerRegistryName -ErrorAction SilentlyContinue
    if (-not $WEContainerRegistry) {
        Write-WELog " Creating Container Registry: $WEContainerRegistryName" " INFO"
        $WEContainerRegistry = New-AzContainerRegistry `
            -ResourceGroupName $WEResourceGroupName `
            -Name $WEContainerRegistryName `
            -Location $WELocation `
            -Sku " Basic" `
            -EnableAdminUser
    }
    Write-WELog " Container Registry: $($WEContainerRegistry.Name)" " INFO"
}


Write-WELog " `nCreating ML Workspace..." " INFO"; 
$WEMLWorkspaceParams = @{
    ResourceGroupName = $WEResourceGroupName
    Name = $WEWorkspaceName
    Location = $WELocation
    Sku = $WESku
}

if ($WEStorageAccount) {
    $WEMLWorkspaceParams.StorageAccount = $WEStorageAccount.Id
}
if ($WEKeyVault) {
    $WEMLWorkspaceParams.KeyVault = $WEKeyVault.ResourceId
}
if ($WEAppInsights) {
    $WEMLWorkspaceParams.ApplicationInsights = $WEAppInsights.Id
}
if ($WEContainerRegistry) {
    $WEMLWorkspaceParams.ContainerRegistry = $WEContainerRegistry.Id
}
; 
$WEMLWorkspace = New-AzMLWorkspace @MLWorkspaceParams

Write-WELog " `nML Workspace $WEWorkspaceName provisioned successfully" " INFO"
Write-WELog " Workspace ID: $($WEMLWorkspace.Id)" " INFO"
Write-WELog " Discovery URL: $($WEMLWorkspace.DiscoveryUrl)" " INFO"

Write-WELog " `nWorkspace Components:" " INFO"
Write-WELog "  Storage Account: $($WEStorageAccount.StorageAccountName)" " INFO"
Write-WELog "  Key Vault: $($WEKeyVault.VaultName)" " INFO"
Write-WELog "  Application Insights: $($WEAppInsights.Name)" " INFO"
if ($WEContainerRegistry) {
    Write-WELog "  Container Registry: $($WEContainerRegistry.Name)" " INFO"
}

Write-WELog " `nML Studio Access:" " INFO"
Write-WELog " Portal URL: https://ml.azure.com/workspaces/$($WEMLWorkspace.WorkspaceId)/overview" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Open Azure ML Studio in the browser" " INFO"
Write-WELog " 2. Create compute instances for development" " INFO"
Write-WELog " 3. Upload or connect to your datasets" " INFO"
Write-WELog " 4. Create and train ML models" " INFO"
Write-WELog " 5. Deploy models as web services" " INFO"
Write-WELog " 6. Set up MLOps pipelines for automation" " INFO"

Write-WELog " `nML Workspace Features:" " INFO"
Write-WELog "  • Jupyter notebooks and VS Code integration" " INFO"
Write-WELog "  • AutoML for automated machine learning" " INFO"
Write-WELog "  • Designer for drag-and-drop ML pipelines" " INFO"
Write-WELog "  • Model management and versioning" " INFO"
Write-WELog "  • Real-time and batch inference endpoints" " INFO"

Write-WELog " `nML Workspace provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
