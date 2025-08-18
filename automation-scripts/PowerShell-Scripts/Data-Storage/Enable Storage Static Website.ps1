<#
.SYNOPSIS
    Enable Storage Static Website

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
    We Enhanced Enable Storage Static Website

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] $WEResourceGroupName,
    [string] $WEStorageAccountName,
    [string] $WEIndexDocument,
    [string] $WEErrorDocument404Path
)

$WEErrorActionPreference = 'Stop'
; 
$storageAccount = Get-AzStorageAccount -ResourceGroupName $WEResourceGroupName -AccountName $WEStorageAccountName; 
$ctx = $storageAccount.Context
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $WEIndexDocument -ErrorDocument404Path $WEErrorDocument404Path

New-Item $WEIndexDocument -Force
Set-Content $WEIndexDocument '<h1>Welcome</h1>'
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $WEIndexDocument -Blob $WEIndexDocument -Properties @{'ContentType' = 'text/html'}

New-Item $WEErrorDocument404Path -Force
Set-Content $WEErrorDocument404Path '<h1>Error: 404 Not Found</h1>'
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $WEErrorDocument404Path -Blob $WEErrorDocument404Path -Properties @{'ContentType' = 'text/html'}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
