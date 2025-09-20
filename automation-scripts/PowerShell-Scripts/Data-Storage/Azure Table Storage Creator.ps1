#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Table Storage Creator

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
    [string]$TableName
)
Write-Host "Creating Table Storage: $TableName" "INFO"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$Table = New-AzStorageTable -Name $TableName -Context $Context
Write-Host "Table Storage created successfully:" "INFO"
Write-Host "Name: $($Table.Name)" "INFO"
Write-Host "Storage Account: $StorageAccountName" "INFO"
Write-Host "Context: $($Context.StorageAccountName)" "INFO"

$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName;
$Key = $Keys[0].Value
Write-Host " `nConnection Information:" "INFO"
Write-Host "Table Endpoint: https://$StorageAccountName.table.core.windows.net/" "INFO"
Write-Host "Table Name: $TableName" "INFO"
Write-Host "Access Key: $($Key.Substring(0,8))..." "INFO"
Write-Host " `nConnection String:" "INFO"
Write-Host "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$Key;TableEndpoint=https://$StorageAccountName.table.core.windows.net/;" "INFO"
Write-Host " `nTable Storage Features:" "INFO"
Write-Host "NoSQL key-value store" "INFO"
Write-Host "Partition and row key structure" "INFO"
Write-Host "Automatic scaling" "INFO"
Write-Host "REST API access" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

