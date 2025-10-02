#Requires -Version 7.4
#Requires -Modules Az.Storage
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create Gen Staticwebsite

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [string] $ResourceGroupName = 'ttk-gen-artifacts',
    [string] [Parameter(mandatory = $true)] $Location
)
if ((Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -ErrorAction SilentlyContinue) -eq $null) {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -Force
}
    [string]$StaticWebsiteStorageAccountName = 'stweb' + ((Get-AzContext).Subscription.Id).Replace('-', '').substring(0, 19)
    [string]$IndexDocumentPath = 'index.htm'
    [string]$IndexDocumentContents = '<h1>Example static website</h1>'
    [string]$ErrorDocument404Path = 'error.htm'
    [string]$ErrorDocumentContents = '<h1>Example 404 error page</h1>'
    [string]$StaticWebsiteStorageAccount = (Get-AzStorageAccount -ErrorAction Stop | Where-Object { $_.StorageAccountName -eq $StaticWebsiteStorageAccountName })
if ($null -eq $StaticWebsiteStorageAccount) {
$StorageaccountSplat = @{
    StorageAccountName = $StaticWebsiteStorageAccountName
    Kind = "StorageV2"
    Type = 'Standard_LRS'
    ResourceGroupName = $ResourceGroupName
    Location = " $Location"
}
New-AzStorageAccount @storageaccountSplat
}
Do {
    Write-Output "Looking for storageAccount: $StaticWebsiteStorageAccount"
    [string]$StaticWebsiteStorageAccount = (Get-AzStorageAccount -ErrorAction Stop | Where-Object { $_.StorageAccountName -eq $StaticWebsiteStorageAccountName })
} until ($null -ne $StaticWebsiteStorageAccountName)
    [string]$ctx = $StaticWebsiteStorageAccount.Context
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $IndexDocumentPath -ErrorDocument404Path $ErrorDocument404Path -Verbose
$TempIndexFile = New-TemporaryFile -ErrorAction Stop
Set-Content $TempIndexFile $IndexDocumentContents -Force
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $TempIndexFile -Blob $IndexDocumentPath -Properties @{'ContentType' = 'text/html'} -Force -Verbose
$TempErrorDocument404File = New-TemporaryFile -ErrorAction Stop
Set-Content $TempErrorDocument404File $ErrorDocumentContents -Force
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $TempErrorDocument404File -Blob $ErrorDocument404Path -Properties @{'ContentType' = 'text/html'} -Force -Verbose
$json = New-Object -ErrorAction Stop System.Collections.Specialized.OrderedDictionary
    [string]$HostName = (($StaticWebsiteStorageAccount.PrimaryEndpoints.Web) -Replace 'https://', '')  -Replace '/', ''
    [string]$json.Add("STATIC-WEBSITE-URL" , $StaticWebsiteStorageAccount.PrimaryEndpoints.Web)
    [string]$json.Add("STATIC-WEBSITE-HOST-NAME" , $HostName)
Write-Output $($json | ConvertTo-json -Depth 30)
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
