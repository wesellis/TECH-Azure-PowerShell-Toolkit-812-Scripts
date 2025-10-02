#Requires -Version 7.4
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Storage Account Provisioning Tool

.DESCRIPTION
    Azure automation for provisioning storage accounts

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
    [string]$StorageAccountName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter()]
    [ValidateSet("Standard_LRS", "Standard_GRS", "Standard_RAGRS", "Standard_ZRS", "Premium_LRS", "Premium_ZRS")]
    [string]$SkuName = "Standard_LRS",

    [Parameter()]
    [ValidateSet("Storage", "StorageV2", "BlobStorage", "FileStorage", "BlockBlobStorage")]
    [string]$Kind = "StorageV2",

    [Parameter()]
    [ValidateSet("Hot", "Cool", "Archive")]
    [string]$AccessTier = "Hot"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [Storage] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Provisioning Storage Account: $StorageAccountName" "INFO"
    Write-Log "Resource Group: $ResourceGroupName" "INFO"
    Write-Log "Location: $Location" "INFO"
    Write-Log "SKU: $SkuName" "INFO"
    Write-Log "Kind: $Kind" "INFO"
    Write-Log "Access Tier: $AccessTier" "INFO"

    # Validate storage account name
    if ($StorageAccountName.Length -lt 3 -or $StorageAccountName.Length -gt 24) {
        throw "Storage account name must be between 3 and 24 characters"
    }
    if ($StorageAccountName -notmatch '^[a-z0-9]+$') {
        throw "Storage account name must contain only lowercase letters and numbers"
    }

    # Create storage account parameters
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name = $StorageAccountName
        Location = $Location
        SkuName = $SkuName
        Kind = $Kind
        EnableHttpsTrafficOnly = $true
        MinimumTlsVersion = "TLS1_2"
        AllowBlobPublicAccess = $false
        ErrorAction = "Stop"
    }

    # Add access tier for appropriate storage types
    if ($Kind -in @("StorageV2", "BlobStorage")) {
        $params.AccessTier = $AccessTier
    }

    # Create the storage account
    Write-Log "Creating storage account..." "INFO"
    $StorageAccount = New-AzStorageAccount @params

    Write-Log "Storage Account $StorageAccountName provisioned successfully" "SUCCESS"
    Write-Log "Primary Blob Endpoint: $($StorageAccount.PrimaryEndpoints.Blob)" "INFO"
    Write-Log "Primary File Endpoint: $($StorageAccount.PrimaryEndpoints.File)" "INFO"
    Write-Log "Primary Queue Endpoint: $($StorageAccount.PrimaryEndpoints.Queue)" "INFO"
    Write-Log "Primary Table Endpoint: $($StorageAccount.PrimaryEndpoints.Table)" "INFO"

    # Get storage account keys
    $Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    Write-Log "Access keys retrieved successfully" "SUCCESS"
    Write-Log "Primary Key: $($Keys[0].Value.Substring(0,10))..." "INFO"

    # Display connection string format
    Write-Log "" "INFO"
    Write-Log "Connection String Format:" "INFO"
    Write-Log "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=[KEY];EndpointSuffix=core.windows.net" "INFO"

} catch {
    Write-Error "Storage account provisioning failed: $($_.Exception.Message)"
    throw
}