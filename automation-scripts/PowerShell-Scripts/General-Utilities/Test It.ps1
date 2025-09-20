<#
.SYNOPSIS
    Test It

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Login-AzureRmAccount
"Script Root Is $PSScriptRoot"
$rgname = " <a name for the resource group>"
New-AzureRmResourceGroup -Name $rgname -Location "West Europe" -Force
$params = @{
    " newStorageAccountName" = " <a name for the storage account>" ;
    " serverPublicDnsName" = " <a name for the public IP>" ;
    " adminUsername" =  " <admin name>" ;
    " adminPassword" = " <admin password>" ;
    " dnsZoneName" = " default.local" ;
}
New-AzureRmResourceGroupDeployment -Name " <deployment name>" -ResourceGroupName $rgname -TemplateFile " $PSScriptRoot/azuredeploy.json"  -TemplateParameterObject $params

