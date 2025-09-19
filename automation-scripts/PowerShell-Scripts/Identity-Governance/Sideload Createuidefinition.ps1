#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Sideload Createuidefinition

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Sideload Createuidefinition

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿#Requires -Version 3.0




[cmdletbinding()]
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] $WEArtifactsStagingDirectory = " ." ,
    [string] $createUIDefFile='createUIDefinition.json',
    [string] $storageContainerName='createuidef',
    [string] $WEStorageResourceGroupLocation, # this must be specified only when the staging resource group needs to be created - first run or if the account has been deleted
    [switch] $WEGov
)

#region Functions

try {

    $WEStorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.Id).Replace('-', '').substring(0, 19)
    $WEStorageAccount = (Get-AzureRmStorageAccount -ErrorAction Stop | Where-Object{$_.StorageAccountName -eq $WEStorageAccountName})

    # Create the storage account if it doesn't already exist
    if ($null -eq $WEStorageAccount) {
        if ($WEStorageResourceGroupLocation -eq "" ) { throw " The StorageResourceGroupLocation parameter is required on first run in a subscription." }
        $WEStorageResourceGroupName = 'ARM_Deploy_Staging'
        New-AzureRmResourceGroup -Location " $WEStorageResourceGroupLocation" -Name $WEStorageResourceGroupName -Force
        $WEStorageAccount = New-AzureRmStorageAccount -StorageAccountName $WEStorageAccountName -Type 'Standard_LRS' -ResourceGroupName $WEStorageResourceGroupName -Location " $WEStorageResourceGroupLocation"
    }

    New-AzureStorageContainer -Name $WEStorageContainerName -Context $WEStorageAccount.Context -ErrorAction SilentlyContinue *>&1

    Set-AzureStorageBlobContent -Container $WEStorageContainerName -File " $WEArtifactsStagingDirectory\$createUIDefFile"  -Context $storageAccount.Context -Force
        
    $uidefurl = New-AzureStorageBlobSASToken -Container $WEStorageContainerName -Blob (Split-Path $createUIDefFile -leaf) -Context $storageAccount.Context -FullUri -Permission r   
    $encodedurl = [uri]::EscapeDataString($uidefurl)

if ($WEGov) {
; 
$target=@"
https://portal.azure.us/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{" providerConfig" :{" createUiDefinition" :" $encodedurl" }}
" @

}
else {
; 
$target=@"
https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{" providerConfig" :{" createUiDefinition" :" $encodedurl" }}
" @

}

Write-Information `n" File: " $uidefurl `n
Write-WELog " Target URL: " " INFO" $target


Start-Process " microsoft-edge:$target"

}
catch {
      throw $_
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
