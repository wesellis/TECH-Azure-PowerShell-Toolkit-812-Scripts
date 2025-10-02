#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    New Azstorageblobsastoken($Templateblobfulluri)

.DESCRIPTION
    New Azstorageblobsastoken($Templateblobfulluri) operation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$StorageAccountName = "outlook1restoredsa"
$StorageAccountResourceGroupName = "CanPrintEquip_Outlook1Restored_RG"
$SetAzCurrentStorageAccountSplat = @{
    Name              = $StorageAccountName
    ResourceGroupName = $StorageAccountResourceGroupName
}
Set-AzCurrentStorageAccount -ErrorAction Stop @setAzCurrentStorageAccountSplat

$NewAzStorageBlobSASTokenSplat = @{
    Container  = $ContainerName
    Permission = 'r'
    FullUri    = $true
    Blob = $Templatename
}

$TemplateBlobFullURI = New-AzStorageBlobSASToken -ErrorAction Stop @newAzStorageBlobSASTokenSplat
$TemplateBlobFullURI



