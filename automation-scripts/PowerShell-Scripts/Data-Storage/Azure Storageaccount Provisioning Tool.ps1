<#
.SYNOPSIS
    Azure Storageaccount Provisioning Tool

.DESCRIPTION
    Azure automation
#>
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
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$SkuName = "Standard_LRS" ,
    [string]$Kind = "StorageV2" ,
    [string]$AccessTier = "Hot"
)
Write-Host "Provisioning Storage Account: $StorageAccountName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host "Location: $Location" "INFO"
Write-Host "SKU: $SkuName" "INFO"
Write-Host "Kind: $Kind" "INFO"
Write-Host "Access Tier: $AccessTier" "INFO"

$params = @{
    ResourceGroupName = $ResourceGroupName
    AccessTier = $AccessTier
    SkuName = $SkuName
    Location = $Location
    EnableHttpsTrafficOnly = $true
    Kind = $Kind
    ErrorAction = "Stop"
    Name = $StorageAccountName
}
$StorageAccount @params
Write-Host "Storage Account $StorageAccountName provisioned successfully" "INFO"
Write-Host "Primary Endpoint: $($StorageAccount.PrimaryEndpoints.Blob)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

