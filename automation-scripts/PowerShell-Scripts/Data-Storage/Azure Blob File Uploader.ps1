<#
.SYNOPSIS
    We Enhanced Azure Blob File Uploader

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEStorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEContainerName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocalFilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$WEBlobName
)

if (-not $WEBlobName) {
    $WEBlobName = Split-Path $WELocalFilePath -Leaf
}

Write-WELog " Uploading file to blob storage:" " INFO"
Write-WELog "  Local file: $WELocalFilePath" " INFO"
Write-WELog "  Blob name: $WEBlobName" " INFO"

$WEStorageAccount = Get-AzStorageAccount -ResourceGroupName $WEResourceGroupName -Name $WEStorageAccountName
$WEContext = $WEStorageAccount.Context
; 
$WEBlob = Set-AzStorageBlobContent `
    -File $WELocalFilePath `
    -Container $WEContainerName `
    -Blob $WEBlobName `
    -Context $WEContext

Write-WELog " ✅ File uploaded successfully!" " INFO"
Write-WELog "  URL: $($WEBlob.ICloudBlob.StorageUri.PrimaryUri)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
