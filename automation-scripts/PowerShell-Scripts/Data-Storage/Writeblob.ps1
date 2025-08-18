<#
.SYNOPSIS
    Writeblob

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

<#
.SYNOPSIS
    We Enhanced Writeblob

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"   
[CmdletBinding()]
param(
    # The subcription Id to log in to
    [Parameter(Mandatory=$true)]
    [string]
    $WESubscriptionId,
    # The tenant Id to that contains the MSI
    [Parameter(Mandatory=$true)]
    [string]
    $WETenantId,
    # The Resource Group Name that contains the storage account to write to
    [Parameter(Mandatory=$true)]
    [string]
    $WEResourceGroupName,
    # The Storage Account to write to
    [Parameter(Mandatory=$true)]
    [string]
    $WEStorageAccountName,
    # The name of the container to write a blob to
    [Parameter(Mandatory=$false)]
    [string]
    $WEContainerName='msi'
)

if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue -ListAvailable)) 
{
    Write-Verbose 'Installing nuget Package Provider'
    Install-PackageProvider -Name nuget -Force
}

Install-Module Az -AllowClobber -Verbose -Force
Install-Module Az.Storage -AllowClobber -Verbose -Force

Connect-AzAccount -Identity -Verbose

$WEContainerName=$WEContainerName.ToLowerInvariant()
$WEBlobName=$env:COMPUTERNAME.ToLowerInvariant(); 
$WEFileName=[System.IO.Path]::GetTempFileName()
Get-Date | Out-File $WEFileName  
; 
$ctx = New-AzStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey -Environment AzureCloud

Set-AzStorageBlobContent -Container $WEContainerName -File $WEFileName -Blob $WEBlobName -Context $ctx -Force



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
