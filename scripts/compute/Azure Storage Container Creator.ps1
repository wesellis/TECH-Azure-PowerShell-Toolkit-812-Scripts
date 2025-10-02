#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure Storage Container Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerName,
    [Parameter()]
    [string]$PublicAccess = "Off"
)
Write-Output "Creating storage container: $ContainerName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName;
    [string]$Context = $StorageAccount.Context
$Container = New-AzStorageContainer -Name $ContainerName -Context $Context -Permission $PublicAccess
Write-Output "Container created successfully:"
Write-Output "Name: $($Container.Name)"
Write-Output "Public Access: $PublicAccess"
Write-Output "Storage Account: $StorageAccountName"
Write-Output "URL: $($Container.CloudBlobContainer.StorageUri.PrimaryUri)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
