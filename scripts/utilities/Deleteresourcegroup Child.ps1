#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Delete Resource Group Child Script

.DESCRIPTION
    Azure automation script for deleting a specific resource group.
    This script connects to Azure using a service principal and removes the specified resource group.

.PARAMETER RGName
    The name of the resource group to delete

.NOTES
    Version: 1.0
    Author: Wes Ellis (wes@wesellis.com)
    Requires appropriate permissions and modules
    Updated to use Az modules instead of deprecated AzureRM
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'The name of the resource group to delete')]
    [String]$RGName
)

$ErrorActionPreference = "Stop"

try {
    $ConnectionName = "AzureRunAsConnection"

    Write-Output "Connecting to Azure..."
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName

    if (-not $ServicePrincipalConnection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }

    $params = @{
        ApplicationId         = $ServicePrincipalConnection.ApplicationId
        TenantId             = $ServicePrincipalConnection.TenantId
        CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint
    }

    Connect-AzAccount -ServicePrincipal @params
    Write-Output "Successfully connected to Azure."

    if ([string]::IsNullOrWhiteSpace($RGName)) {
        Write-Warning "Resource group name is empty. Please verify the parameter."
        return
    }

    $trimmedRGName = $RGName.Trim()
    Write-Output "Checking if resource group '$trimmedRGName' exists..."

    $resourceGroup = Get-AzResourceGroup -Name $trimmedRGName -ErrorAction SilentlyContinue

    if ($null -eq $resourceGroup) {
        Write-Warning "Resource group '$trimmedRGName' does not exist."
        return
    }

    Write-Output "Removing resource group '$trimmedRGName'..."
    Remove-AzResourceGroup -Name $trimmedRGName -Force -AsJob

    Write-Output "Resource group deletion initiated successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}