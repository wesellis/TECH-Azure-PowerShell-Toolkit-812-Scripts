#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Sideload Createuidefinition

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] $ArtifactsStagingDirectory = " ." ,
    [string] $CreateUIDefFile='createUIDefinition.json',
    [string] $StorageContainerName='createuidef',
    [string] $StorageResourceGroupLocation,
    [switch] $Gov
)
try {
    [string]$StorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.Id).Replace('-', '').substring(0, 19)
    [string]$StorageAccount = (Get-AzureRmStorageAccount -ErrorAction Stop | Where-Object{$_.StorageAccountName -eq $StorageAccountName})
    if ($null -eq $StorageAccount) {
        if ($StorageResourceGroupLocation -eq "" ) { throw "The StorageResourceGroupLocation parameter is required on first run in a subscription." }
    [string]$StorageResourceGroupName = 'ARM_Deploy_Staging'
        New-AzureRmResourceGroup -Location " $StorageResourceGroupLocation" -Name $StorageResourceGroupName -Force
    [string]$StorageAccount = New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Type 'Standard_LRS' -ResourceGroupName $StorageResourceGroupName -Location " $StorageResourceGroupLocation"
    }
    New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue *>&1
    Set-AzureStorageBlobContent -Container $StorageContainerName -File " $ArtifactsStagingDirectory\$CreateUIDefFile"  -Context $StorageAccount.Context -Force
    [string]$uidefurl = New-AzureStorageBlobSASToken -Container $StorageContainerName -Blob (Split-Path $CreateUIDefFile -leaf) -Context $StorageAccount.Context -FullUri -Permission r
    [string]$encodedurl = [uri]::EscapeDataString($uidefurl)
if ($Gov) {
    [string]$target=@"
https://portal.azure.us/
" @
}
else {
    [string]$target=@"
https://portal.azure.com/
" @
}
Write-Information `n"File: " $uidefurl `n
Write-Output "Target URL: " $target
Start-Process " microsoft-edge:$target"
}
catch {
      throw $_`n}
