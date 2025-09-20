#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure Storage Container Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
Write-Host "Creating storage container: $ContainerName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName;
$Context = $StorageAccount.Context
$Container = New-AzStorageContainer -Name $ContainerName -Context $Context -Permission $PublicAccess
Write-Host "Container created successfully:"
Write-Host "Name: $($Container.Name)"
Write-Host "Public Access: $PublicAccess"
Write-Host "Storage Account: $StorageAccountName"
Write-Host "URL: $($Container.CloudBlobContainer.StorageUri.PrimaryUri)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


