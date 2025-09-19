#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$false)]
    [string]$PublicAccess = "Off"
)

#region Functions

Write-Information "Creating storage container: $ContainerName"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context

$Container = New-AzStorageContainer -Name $ContainerName -Context $Context -Permission $PublicAccess

Write-Information "Container created successfully:"
Write-Information "  Name: $($Container.Name)"
Write-Information "  Public Access: $PublicAccess"
Write-Information "  Storage Account: $StorageAccountName"
Write-Information "  URL: $($Container.CloudBlobContainer.StorageUri.PrimaryUri)"


#endregion
