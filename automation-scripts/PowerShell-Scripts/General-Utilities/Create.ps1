#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$rgname = "DnsForwardExample"
$params = @{
    " vmName" = " dnsproxy1" ;
    " adminUsername" =" mradmin" ;
    " adminPassword" ="Admin123!" ;
    " storageAccName" =" $($rgname)stor" .ToLower();
}
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
Login-AzureRmAccount
New-AzureRmResourceGroup -Name $rgname -Location " northeurope"
New-AzureRmResourceGroupDeployment -Name $rgname -ResourceGroupName $rgname -TemplateFile " $scriptDir\azuredeploy.json" -TemplateParameterObject $params
$params.vmName = " dnsproxy2"
New-AzureRmResourceGroupDeployment -Name $rgname -ResourceGroupName $rgname -TemplateFile " $scriptDir\azuredeploy.json" -TemplateParameterObject $params\n

