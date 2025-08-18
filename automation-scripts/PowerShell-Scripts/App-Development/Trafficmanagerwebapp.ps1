<#
.SYNOPSIS
    We Enhanced Trafficmanagerwebapp

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

$rgName = "TrafficManagerWebAppExample"


Import-Module AzureRM.TrafficManager
Import-Module AzureRM.Resources


Login-AzureRmAccount


$scriptDir = Split-Path $WEMyInvocation.MyCommand.Path
New-AzureRmResourceGroup -Location " northeurope" -Name $rgName
New-AzureRmResourceGroupDeployment -Verbose -Force -ResourceGroupName $rgName -TemplateFile " $scriptDir\azuredeploy.json" -TemplateParameterFile " $scriptDir\azuredeploy.parameters.json"

; 
$x = Get-AzureRmTrafficManagerProfile -ResourceGroupName $rgName
$x
$x.Endpoints


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================