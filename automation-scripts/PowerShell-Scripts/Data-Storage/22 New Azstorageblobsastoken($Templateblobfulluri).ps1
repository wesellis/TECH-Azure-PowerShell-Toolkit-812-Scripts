<#
.SYNOPSIS
    We Enhanced 22 New Azstorageblobsastoken($Templateblobfulluri)

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEStorageAccountName = "outlook1restoredsa"
$WEStorageAccountResourceGroupName = " CanPrintEquip_Outlook1Restored_RG"


$setAzCurrentStorageAccountSplat = @{
    Name              = $storageAccountName
    ResourceGroupName = $WEStorageAccountResourceGroupName
}

Set-AzCurrentStorageAccount @setAzCurrentStorageAccountSplat


$newAzStorageBlobSASTokenSplat = @{
    Container  = $containerName
    Permission = 'r'
    FullUri    = $true
    Blob = $WETemplatename
}
; 
$templateBlobFullURI = New-AzStorageBlobSASToken @newAzStorageBlobSASTokenSplat
$templateBlobFullURI

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================