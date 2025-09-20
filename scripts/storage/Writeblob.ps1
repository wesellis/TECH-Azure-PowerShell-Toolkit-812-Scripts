#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Writeblob

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    # The subcription Id to log in to
    [Parameter(Mandatory)]
    [string]
    $SubscriptionId,
    # The tenant Id to that contains the MSI
    [Parameter(Mandatory)]
    [string]
    $TenantId,
    # The Resource Group Name that contains the storage account to write to
    [Parameter(Mandatory)]
    [string]
    $ResourceGroupName,
    # The Storage Account to write to
    [Parameter(Mandatory)]
    [string]
    $StorageAccountName,
    # The name of the container to write a blob to
    [Parameter()]
    [string]
    $ContainerName='msi'
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
$ContainerName=$ContainerName.ToLowerInvariant()
$BlobName=$env:COMPUTERNAME.ToLowerInvariant();
$FileName=[System.IO.Path]::GetTempFileName()
Get-Date | Out-File $FileName

$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Environment AzureCloud
Set-AzStorageBlobContent -Container $ContainerName -File $FileName -Blob $BlobName -Context $ctx -Force
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

