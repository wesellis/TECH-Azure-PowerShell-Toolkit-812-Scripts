<#
.SYNOPSIS
    Trafficmanagerwebapp

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$rgName = "TrafficManagerWebAppExample"
Import-Module AzureRM.TrafficManager
Import-Module AzureRM.Resources
Login-AzureRmAccount
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
New-AzureRmResourceGroup -Location " northeurope" -Name $rgName
New-AzureRmResourceGroupDeployment -Verbose -Force -ResourceGroupName $rgName -TemplateFile " $scriptDir\azuredeploy.json" -TemplateParameterFile " $scriptDir\azuredeploy.parameters.json"
$x = Get-AzureRmTrafficManagerProfile -ResourceGroupName $rgName
$x
$x.Endpoints

