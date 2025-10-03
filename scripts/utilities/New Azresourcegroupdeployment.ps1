#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    New Azresourcegroupdeployment

.DESCRIPTION
    New Azresourcegroupdeployment operation
    Adds an Azure deployment to a resource group.

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName = "CanPrintEquip_Outlook1Restored_RG",

    [Parameter(Mandatory = $true)]
    [string]$DeploymentName = 'Outlook1Restored_RG_Deployment',

    [Parameter(Mandatory = $true)]
    [string]$TemplateUri,

    [Parameter(Mandatory = $true)]
    [string]$VirtualMachineName = 'Outlook1'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$newAzResourceGroupDeploymentSplat = @{
    Name               = $DeploymentName
    TemplateUri        = $TemplateUri
    ResourceGroupName  = $ResourceGroupName
    VirtualMachineName = $VirtualMachineName
}
New-AzResourceGroupDeployment -ErrorAction Stop @newAzResourceGroupDeploymentSplat