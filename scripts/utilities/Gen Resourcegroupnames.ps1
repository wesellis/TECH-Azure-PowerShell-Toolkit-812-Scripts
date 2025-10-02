#Requires -Version 7.4

<#
.SYNOPSIS
    Gen Resourcegroupnames - Generate Resource Group Names for Azure Deployment

.DESCRIPTION
    Azure automation script that generates resource group names for deployment and checks for prerequisites.
    This script will generate the resource group names for deployment and check for prereqs.
    If specified, the prereq and the sample resource group name will be the same - this is required by some samples, but should not be the default.

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER ResourceGroupNamePrefix
    Prefix for the resource group name (default: "azdo")

.PARAMETER SampleFolder
    Path to the sample folder containing configuration

.EXAMPLE
    PS C:\> .\Gen_Resourcegroupnames.ps1 -ResourceGroupNamePrefix "myproject" -SampleFolder "C:\samples\webapp"
    Generates resource group names with the specified prefix

.INPUTS
    String parameters for resource group naming configuration

.OUTPUTS
    Azure DevOps variables for resource group names

.NOTES
    This script sets Azure DevOps pipeline variables for resource group naming
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ResourceGroupNamePrefix = "azdo",

    [Parameter()]
    [string]$SampleFolder
)

$ErrorActionPreference = "Stop"

try {
    $SettingsFilePath = "$SampleFolder\prereqs\.settings.json"

    if (Test-Path $SettingsFilePath) {
        Write-Output "Found settings file... $SettingsFilePath"
        $settings = Get-Content -Path $SettingsFilePath -Raw | ConvertFrom-Json
        Write-Output $settings
    }

    if ($settings.psobject.Members.Name -contains "PrereqResourceGroupNameSuffix") {
        $PrereqResourceGroupNameSuffix = $settings.PrereqResourceGroupNameSuffix
    }
    else {
        $PrereqResourceGroupNameSuffix = "-prereqs" # by default we will deploy to a separate resource group - it's a more thorough test on resourceIds
    }

    $ResourceGroupName = "$ResourceGroupNamePrefix-$(New-Guid)"
    Write-Output "##vso[task.setvariable variable=resourceGroup.name]$ResourceGroupName"
    Write-Output "##vso[task.setvariable variable=prereq.resourceGroup.name]$ResourceGroupName$PrereqResourceGroupNameSuffix"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}