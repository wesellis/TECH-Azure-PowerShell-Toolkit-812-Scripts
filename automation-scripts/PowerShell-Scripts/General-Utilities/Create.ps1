<#
.SYNOPSIS
    We Enhanced Create

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

$rgname = "DnsForwardExample"
; 
$params = @{
    " vmName" = " dnsproxy1";
    " adminUsername"=" mradmin";
    " adminPassword"=" Admin123!";
    " storageAccName"=" $($rgname)stor".ToLower();
}


$scriptDir = Split-Path $WEMyInvocation.MyCommand.Path


Import-Module AzureRM.Resources


Login-AzureRmAccount


New-AzureRmResourceGroup -Name $rgname -Location " northeurope"
New-AzureRmResourceGroupDeployment -Name $rgname -ResourceGroupName $rgname -TemplateFile " $scriptDir\azuredeploy.json" -TemplateParameterObject $params


$params.vmName = " dnsproxy2"
New-AzureRmResourceGroupDeployment -Name $rgname -ResourceGroupName $rgname -TemplateFile " $scriptDir\azuredeploy.json" -TemplateParameterObject $params



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================