#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create ESET security deployment on Azure.

.DESCRIPTION
    This script creates an Azure Resource Group and deploys a Windows VM template
    with ESET security configurations for endpoint protection.

.PARAMETER ResourceGroupName
    The name of the Azure Resource Group to create.

.PARAMETER Location
    The Azure region where resources will be deployed.

.PARAMETER TemplateUri
    The URI of the ARM template to deploy.

.EXAMPLE
    .\Eset-Create-Deployment.ps1 -ResourceGroupName "WindowsSecureRG" -Location "East US"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Requires Az.Resources module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "WindowsSecureRG",

    [Parameter(Mandatory = $false)]
    [string]$Location = "East US",

    [Parameter(Mandatory = $false)]
    [string]$TemplateUri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-simple-windows-vm/azuredeploy.json"
)

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Creating Azure Resource Group '$ResourceGroupName' in location '$Location'..."

    # Check if resource group already exists
    $existingRG = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($existingRG) {
        Write-Output "Resource group '$ResourceGroupName' already exists in location '$($existingRG.Location)'."
    }
    else {
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Output "Resource group '$ResourceGroupName' created successfully in location '$Location'."
    }

    Write-Output "Deploying ARM template from: $TemplateUri"
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri $TemplateUri `
        -Name "EsetSecureDeployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    Write-Output "ESET security deployment completed successfully."
    Write-Output "Deployment Name: $($deployment.DeploymentName)"
    Write-Output "Deployment State: $($deployment.ProvisioningState)"
}
catch {
    Write-Error "Failed to create ESET deployment: $($_.Exception.Message)"
    throw
}