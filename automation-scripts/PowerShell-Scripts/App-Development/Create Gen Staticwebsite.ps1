<#
.SYNOPSIS
    Create Gen Staticwebsite

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] $ResourceGroupName = 'ttk-gen-artifacts',
    [string] [Parameter(mandatory = $true)] $Location
)
if ((Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -ErrorAction SilentlyContinue) -eq $null) {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -Force
}
$staticWebsiteStorageAccountName = 'stweb' + ((Get-AzContext).Subscription.Id).Replace('-', '').substring(0, 19)
$indexDocumentPath = 'index.htm'
$indexDocumentContents = '<h1>Example static website</h1>'
$errorDocument404Path = 'error.htm'
$errorDocumentContents = '<h1>Example 404 error page</h1>'
$staticWebsiteStorageAccount = (Get-AzStorageAccount -ErrorAction Stop | Where-Object { $_.StorageAccountName -eq $staticWebsiteStorageAccountName })
if ($null -eq $staticWebsiteStorageAccount) {
    $storageaccountSplat = @{
    StorageAccountName = $staticWebsiteStorageAccountName
    Kind = "StorageV2"
    Type = 'Standard_LRS'
    ResourceGroupName = $ResourceGroupName
    Location = " $Location"
}
New-AzStorageAccount @storageaccountSplat
}
Do {
    Write-Host "Looking for storageAccount: $staticWebsiteStorageAccount"
    $staticWebsiteStorageAccount = (Get-AzStorageAccount -ErrorAction Stop | Where-Object { $_.StorageAccountName -eq $staticWebsiteStorageAccountName })
} until ($null -ne $staticWebsiteStorageAccountName)
$ctx = $staticWebsiteStorageAccount.Context
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $indexDocumentPath -ErrorDocument404Path $errorDocument404Path -Verbose
$tempIndexFile = New-TemporaryFile -ErrorAction Stop
Set-Content $tempIndexFile $indexDocumentContents -Force
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $tempIndexFile -Blob $indexDocumentPath -Properties @{'ContentType' = 'text/html'} -Force -Verbose
$tempErrorDocument404File = New-TemporaryFile -ErrorAction Stop
Set-Content $tempErrorDocument404File $errorDocumentContents -Force
Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $tempErrorDocument404File -Blob $errorDocument404Path -Properties @{'ContentType' = 'text/html'} -Force -Verbose
$json = New-Object -ErrorAction Stop System.Collections.Specialized.OrderedDictionary #This keeps things in the order we entered them, instead of: New-Object -TypeName Hashtable;
$hostName = (($staticWebsiteStorageAccount.PrimaryEndpoints.Web) -Replace 'https://', '')  -Replace '/', ''
$json.Add("STATIC-WEBSITE-URL" , $staticWebsiteStorageAccount.PrimaryEndpoints.Web)
$json.Add("STATIC-WEBSITE-HOST-NAME" , $hostName)
Write-Output $($json | ConvertTo-json -Depth 30)
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

