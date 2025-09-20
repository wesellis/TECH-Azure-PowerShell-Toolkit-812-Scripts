#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    New Azresourcegroupdeployment

.DESCRIPTION
    New Azresourcegroupdeployment operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    DeploymentName          : Outlook1Restored_RG_Deployment
ResourceGroupName       : CanPrintEquip_Outlook1Restored_RG
ProvisioningState       : Succeeded
Timestamp               : 2020-12-13 2:24:10 AM
Mode                    : Incremental
TemplateLink            :
                          Uri            : https://outlook1restoredsa.blob.core.windows.net/outlook1-6449bf5b196841f69f31a91cad72e551/azu
                          redeploy064ee552-fb05-4d1c-a2c3-80051f40b533.json?sv=2019-07-07&sr=b&sig=05kIcwpQ0pemTl0VbJ5C6jadzJuBVUONINvMQ0
                          u%2FiDY%3D&se=2020-12-13T03%3A12%3A13Z&sp=r
                          ContentVersion : 1.0.0.0
Parameters              :
                          Name                           Type                       Value
                          =============================  =========================  ==========
                          virtualMachineName             String                     Outlook1
                          virtualNetwork                 String                     Outlook1_group-vnet
                          virtualNetworkResourceGroup    String                     CanPrintEquip_Outlook_RG
                          virtualNetworkResourceGroup    String                     CanPrintEquip_Outlook_RG
                          subnet                         String                     Outlook1-subnet
                          osDiskName                     String                     Outlook1OSDisk
                          networkInterfacePrefixName     String                     Outlook1RestoredNIC
                          publicIpAddressName            String                     Outlook1Restoredip
Outputs                 :
DeploymentDebugLogLevel :
    General notes
    Adds an Azure deployment to a resource group.
$StorageAccountResourceGroupName = "CanPrintEquip_Outlook1Restored_RG";
$VMName = 'Outlook1'
$newAzResourceGroupDeploymentSplat = @{
    Name               = 'Outlook1Restored_RG_Deployment'
    TemplateUri        = $templateBlobFullURI
    # storageAccountType = 'Standard_GRS'
    ResourceGroupName  = $StorageAccountResourceGroupName
    VirtualMachineName = $VMName
}
New-AzResourceGroupDeployment -ErrorAction Stop @newAzResourceGroupDeploymentSplat

