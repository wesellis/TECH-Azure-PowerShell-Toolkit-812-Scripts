<#
.SYNOPSIS
    Copy Data

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Invoke-WebRequest -Uri "${env:contentUri}" -OutFile " ${env:csvFileName}"
$ctx = New-AzStorageContext -StorageAccountName " ${Env:storageAccountName}" -StorageAccountKey " ${Env:storageAccountKey}"
New-AzStorageContainer -Context $ctx -Name " ${env:containerName}" -Verbose
$params = @{
    File = " ${env:csvFileName}"
    Context = $ctx
    Blob = " ${env:csvFileName}"
    Container = " ${Env:containerName}"
    StandardBlobTier = "Hot"
}
Set-AzStorageBlobContent @params

