<#
.SYNOPSIS
    We Enhanced Test It

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

Login-AzureRmAccount 

"Script Root Is $WEPSScriptRoot"

$rgname = " <a name for the resource group>"

New-AzureRmResourceGroup -Name $rgname -Location " West Europe" -Force
; 
$params = @{
    " newStorageAccountName" = " <a name for the storage account>";
    " serverPublicDnsName" = " <a name for the public IP>";
    " adminUsername" =  " <admin name>";
    " adminPassword" = " <admin password>";
    " dnsZoneName" = " default.local";
}

New-AzureRmResourceGroupDeployment -Name " <deployment name>" -ResourceGroupName $rgname -TemplateFile " $WEPSScriptRoot/azuredeploy.json"  -TemplateParameterObject $params


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================