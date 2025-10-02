#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure Fileshare Creator

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
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ShareName,
    [Parameter()]
    [int]$QuotaInGB = 1024
)
Write-Output "Creating File Share: $ShareName" "INFO"
    [string]$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    [string]$Context = $StorageAccount.Context
    $params = @{
    ErrorAction = "Stop"
    Context = $Context
    QuotaGiB = $QuotaInGB
    Name = $ShareName
}
    [string]$FileShare @params
Write-Output "File Share created successfully:" "INFO"
Write-Output "Name: $($FileShare.Name)" "INFO"
Write-Output "Quota: $QuotaInGB GB" "INFO"
Write-Output "Storage Account: $StorageAccountName" "INFO"
    [string]$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName;
    [string]$Key = $Keys[0].Value
Write-Output " `nConnection Information:" "INFO"
Write-Output "UNC Path: \\$StorageAccountName.file.core.windows.net\$ShareName" "INFO"
Write-Output "Mount Command (Windows):" "INFO"
Write-Output "    net use Z: \\$StorageAccountName.file.core.windows.net\$ShareName /u:AZURE\$StorageAccountName $Key" "INFO"
Write-Output "Mount Command (Linux):" "INFO"
Write-Output "    sudo mount -t cifs //$StorageAccountName.file.core.windows.net/$ShareName /mnt/myfileshare -o vers=3.0,username=$StorageAccountName,password=$Key,dir_mode=0777,file_mode=0777" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
