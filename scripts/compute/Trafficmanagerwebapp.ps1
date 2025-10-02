#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Trafficmanagerwebapp

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$RgName = "TrafficManagerWebAppExample"
Login-AzureRmAccount
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
New-AzureRmResourceGroup -Location " northeurope" -Name $RgName
New-AzureRmResourceGroupDeployment -Verbose -Force -ResourceGroupName $RgName -TemplateFile " $ScriptDir\azuredeploy.json" -TemplateParameterFile " $ScriptDir\azuredeploy.parameters.json"
$x = Get-AzureRmTrafficManagerProfile -ResourceGroupName $RgName
$x
$x.Endpoints



