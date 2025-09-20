#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Sideload Createuidefinition

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#Requires -Version 3.0
[cmdletbinding()]
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] $ArtifactsStagingDirectory = " ." ,
    [string] $createUIDefFile='createUIDefinition.json',
    [string] $storageContainerName='createuidef',
    [string] $StorageResourceGroupLocation, # this must be specified only when the staging resource group needs to be created - first run or if the account has been deleted
    [switch] $Gov
)
try {
    $StorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.Id).Replace('-', '').substring(0, 19)
    $StorageAccount = (Get-AzureRmStorageAccount -ErrorAction Stop | Where-Object{$_.StorageAccountName -eq $StorageAccountName})
    # Create the storage account if it doesn't already exist
    if ($null -eq $StorageAccount) {
        if ($StorageResourceGroupLocation -eq "" ) { throw "The StorageResourceGroupLocation parameter is required on first run in a subscription." }
        $StorageResourceGroupName = 'ARM_Deploy_Staging'
        New-AzureRmResourceGroup -Location " $StorageResourceGroupLocation" -Name $StorageResourceGroupName -Force
        $StorageAccount = New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Type 'Standard_LRS' -ResourceGroupName $StorageResourceGroupName -Location " $StorageResourceGroupLocation"
    }
    New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue *>&1
    Set-AzureStorageBlobContent -Container $StorageContainerName -File " $ArtifactsStagingDirectory\$createUIDefFile"  -Context $storageAccount.Context -Force
    $uidefurl = New-AzureStorageBlobSASToken -Container $StorageContainerName -Blob (Split-Path $createUIDefFile -leaf) -Context $storageAccount.Context -FullUri -Permission r
    $encodedurl = [uri]::EscapeDataString($uidefurl)
if ($Gov) {
$target=@"
https://portal.azure.us/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{" providerConfig" :{" createUiDefinition" :" $encodedurl" }}
" @
}
else {
$target=@"
https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{" providerConfig" :{" createUiDefinition" :" $encodedurl" }}
" @
}
Write-Information `n"File: " $uidefurl `n
Write-Host "Target URL: " $target
Start-Process " microsoft-edge:$target"
}
catch {
      throw $_
}\n

