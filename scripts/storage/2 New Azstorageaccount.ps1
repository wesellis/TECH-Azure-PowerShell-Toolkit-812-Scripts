#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Create new Azure Storage Account

.DESCRIPTION
    Creates a new Azure Storage Account with configurable settings including
    SKU, kind, access tier, and minimum TLS version
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0

.PARAMETER ResourceGroupName
    Name of the resource group where the storage account will be created

.PARAMETER StorageAccountName
    Name of the storage account (must be 3-24 characters, lowercase letters and numbers only)

.PARAMETER Location
    Azure region where the storage account will be created

.PARAMETER SkuName
    SKU name for the storage account. Valid values:
    Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS, Premium_ZRS, Standard_GZRS, Standard_RAGZRS

.PARAMETER Kind
    Kind of storage account. Valid values:
    Storage, StorageV2, BlobStorage, BlockBlobStorage, FileStorage

.PARAMETER AccessTier
    Access tier for the storage account (Hot or Cool)

.PARAMETER MinimumTlsVersion
    Minimum TLS version to be permitted on requests to storage. Default is TLS1_2

.PARAMETER Tags
    Hashtable of tags to apply to the storage account

.EXAMPLE
    .\2-New-Azstorageaccount.ps1 -ResourceGroupName "rg-prod" -StorageAccountName "mystorage123" -Location "eastus"
    Creates a storage account with default settings

.EXAMPLE
    .\2-New-Azstorageaccount.ps1 -ResourceGroupName "rg-prod" -StorageAccountName "mystorage123" -Location "eastus" -SkuName "Premium_LRS" -Kind "BlockBlobStorage"
    Creates a premium block blob storage account

.EXAMPLE
    $tags = @{Environment="Production"; Department="IT"}
    .\2-New-Azstorageaccount.ps1 -ResourceGroupName "rg-prod" -StorageAccountName "mystorage123" -Location "eastus" -Tags $tags
    Creates a storage account with custom tags

.NOTES
    Storage account names must be between 3 and 24 characters and use lowercase letters and numbers only
    Requires Az.Storage module and appropriate permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(3, 24)]
    [ValidatePattern('^[a-z0-9]+$')]
    [string]$StorageAccountName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter()]
    [ValidateSet('Standard_LRS', 'Standard_ZRS', 'Standard_GRS', 'Standard_RAGRS', 'Premium_LRS', 'Premium_ZRS', 'Standard_GZRS', 'Standard_RAGZRS')]
    [string]$SkuName = 'Standard_LRS',

    [Parameter()]
    [ValidateSet('Storage', 'StorageV2', 'BlobStorage', 'BlockBlobStorage', 'FileStorage')]
    [string]$Kind = 'StorageV2',

    [Parameter()]
    [ValidateSet('Hot', 'Cool')]
    [string]$AccessTier = 'Hot',

    [Parameter()]
    [ValidateSet('TLS1_0', 'TLS1_1', 'TLS1_2')]
    [string]$MinimumTlsVersion = 'TLS1_2',

    [Parameter()]
    [hashtable]$Tags = @{}
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { 'Continue' } else { 'SilentlyContinue' }

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO"    = "Cyan"
        "WARN"    = "Yellow"
        "ERROR"   = "Red"
        "SUCCESS" = "Green"
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

try {
    Write-LogMessage "Creating Azure Storage Account" -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    Write-LogMessage "Storage Account Name: $StorageAccountName" -Level "INFO"
    Write-LogMessage "Location: $Location" -Level "INFO"
    Write-LogMessage "SKU: $SkuName" -Level "INFO"
    Write-LogMessage "Kind: $Kind" -Level "INFO"
    Write-LogMessage "Access Tier: $AccessTier" -Level "INFO"
    Write-LogMessage "Minimum TLS Version: $MinimumTlsVersion" -Level "INFO"

    # Add default tags
    $datetime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $defaultTags = @{
        "CreatedDate" = $datetime
        "ManagedBy"   = "Azure PowerShell Toolkit"
        "Location"    = $Location
        "SkuName"     = $SkuName
        "Kind"        = $Kind
        "AccessTier"  = $AccessTier
    }

    # Merge default tags with provided tags (provided tags take precedence)
    $finalTags = $defaultTags.Clone()
    foreach ($key in $Tags.Keys) {
        $finalTags[$key] = $Tags[$key]
    }

    Write-Verbose "Final tags: $($finalTags | Out-String)"

    # Create the storage account
    $newAzStorageAccountSplat = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $StorageAccountName
        Location          = $Location
        SkuName           = $SkuName
        Kind              = $Kind
        AccessTier        = $AccessTier
        MinimumTlsVersion = $MinimumTlsVersion
        Tag               = $finalTags
    }

    Write-LogMessage "Creating storage account..." -Level "INFO"
    $storageAccount = New-AzStorageAccount @newAzStorageAccountSplat -ErrorAction Stop

    Write-LogMessage "Storage account created successfully" -Level "SUCCESS"
    Write-LogMessage "Storage Account ID: $($storageAccount.Id)" -Level "INFO"
    Write-LogMessage "Primary Location: $($storageAccount.PrimaryLocation)" -Level "INFO"
    Write-LogMessage "Status: $($storageAccount.ProvisioningState)" -Level "INFO"

    # Return the storage account object
    return $storageAccount

} catch {
    Write-LogMessage "Failed to create storage account: $($_.Exception.Message)" -Level "ERROR"
    throw
}
