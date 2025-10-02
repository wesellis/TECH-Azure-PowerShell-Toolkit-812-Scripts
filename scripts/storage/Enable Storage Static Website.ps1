#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Enable Storage Static Website

.DESCRIPTION
    Azure automation

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] $ResourceGroupName,
    [string] $StorageAccountName,
    [string] $IndexDocument,
    [string] $ErrorDocument404Path
)
try {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName;
    $ctx = $StorageAccount.Context
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $IndexDocument -ErrorDocument404Path $ErrorDocument404Path
New-Item $IndexDocument -Force -ErrorAction Stop
Set-Content $IndexDocument '<h1>Welcome</h1>' -ErrorAction Stop
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $IndexDocument -Blob $IndexDocument -Properties @{'ContentType' = 'text/html'}
New-Item $ErrorDocument404Path -Force -ErrorAction Stop
Set-Content $ErrorDocument404Path '<h1>Error: 404 Not Found</h1>' -ErrorAction Stop
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $ErrorDocument404Path -Blob $ErrorDocument404Path -Properties @{'ContentType' = 'text/html'}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
