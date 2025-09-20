#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Enable Static Website

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = 'Stop'
$storageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -AccountName $env:StorageAccountName
$ctx = $storageAccount.Context
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $env:IndexDocumentPath -ErrorDocument404Path $env:ErrorDocument404Path
$tempIndexFile = New-TemporaryFile -ErrorAction Stop
Set-Content $tempIndexFile $env:IndexDocumentContents -Force
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $tempIndexFile -Blob $env:IndexDocumentPath -Properties @{'ContentType' = 'text/html'} -Force
$tempErrorDocument404File = New-TemporaryFile -ErrorAction Stop
Set-Content $tempErrorDocument404File $env:ErrorDocument404Contents -Force
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $tempErrorDocument404File -Blob $env:ErrorDocument404Path -Properties @{'ContentType' = 'text/html'} -Force


