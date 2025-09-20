#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    New Azstorageblobsastoken($Templateblobfulluri)

.DESCRIPTION
    New Azstorageblobsastoken($Templateblobfulluri) operation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$StorageAccountName = "outlook1restoredsa"
$StorageAccountResourceGroupName = "CanPrintEquip_Outlook1Restored_RG"
$setAzCurrentStorageAccountSplat = @{
    Name              = $storageAccountName
    ResourceGroupName = $StorageAccountResourceGroupName
}
Set-AzCurrentStorageAccount -ErrorAction Stop @setAzCurrentStorageAccountSplat

$newAzStorageBlobSASTokenSplat = @{
    Container  = $containerName
    Permission = 'r'
    FullUri    = $true
    Blob = $Templatename
}

$templateBlobFullURI = New-AzStorageBlobSASToken -ErrorAction Stop @newAzStorageBlobSASTokenSplat
$templateBlobFullURI\n

