#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Writeblob

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]
    [string]$SubscriptionId,
    [Parameter(Mandatory)]
    [string]
    [string]$TenantId,
    [Parameter(Mandatory)]
    [string]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]
    [string]$StorageAccountName,
    [Parameter()]
    [string]
    [string]$ContainerName='msi'
)
try {
if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue -ListAvailable))
{
    Write-Verbose 'Installing nuget Package Provider'
    Install-PackageProvider -Name nuget -Force
}
Install-Module Az -AllowClobber -Verbose -Force
Install-Module Az.Storage -AllowClobber -Verbose -Force
Connect-AzAccount -Identity -Verbose
    [string]$ContainerName=$ContainerName.ToLowerInvariant()
    [string]$BlobName=$env:COMPUTERNAME.ToLowerInvariant();
    [string]$FileName=[System.IO.Path]::GetTempFileName()
Get-Date | Out-File $FileName
    [string]$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Environment AzureCloud
Set-AzStorageBlobContent -Container $ContainerName -File $FileName -Blob $BlobName -Context $ctx -Force
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
