#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Fileshare Creator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
Write-Host "Creating File Share: $ShareName" "INFO"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$params = @{
    ErrorAction = "Stop"
    Context = $Context
    QuotaGiB = $QuotaInGB
    Name = $ShareName
}
$FileShare @params
Write-Host "File Share created successfully:" "INFO"
Write-Host "Name: $($FileShare.Name)" "INFO"
Write-Host "Quota: $QuotaInGB GB" "INFO"
Write-Host "Storage Account: $StorageAccountName" "INFO"

$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName;
$Key = $Keys[0].Value
Write-Host " `nConnection Information:" "INFO"
Write-Host "UNC Path: \\$StorageAccountName.file.core.windows.net\$ShareName" "INFO"
Write-Host "Mount Command (Windows):" "INFO"
Write-Host "    net use Z: \\$StorageAccountName.file.core.windows.net\$ShareName /u:AZURE\$StorageAccountName $Key" "INFO"
Write-Host "Mount Command (Linux):" "INFO"
Write-Host "    sudo mount -t cifs //$StorageAccountName.file.core.windows.net/$ShareName /mnt/myfileshare -o vers=3.0,username=$StorageAccountName,password=$Key,dir_mode=0777,file_mode=0777" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

