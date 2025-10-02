#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Table Storage Creator

.DESCRIPTION
    Azure automation for creating and configuring Azure Table Storage

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

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
    [string]$TableName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [Azure-Table] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Creating Table Storage: $TableName" "INFO"

    # Get storage account
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $Context = $StorageAccount.Context

    # Create table
    $Table = New-AzStorageTable -Name $TableName -Context $Context

    Write-Log "Table Storage created successfully:" "SUCCESS"
    Write-Log "Name: $($Table.Name)" "INFO"
    Write-Log "Storage Account: $StorageAccountName" "INFO"
    Write-Log "Context: $($Context.StorageAccountName)" "INFO"

    # Get connection information
    $Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $Key = $Keys[0].Value

    Write-Log "`nConnection Information:" "INFO"
    Write-Log "Table Endpoint: https://$StorageAccountName.table.core.windows.net/" "INFO"
    Write-Log "Table Name: $TableName" "INFO"
    Write-Log "Access Key: $($Key.Substring(0,8))..." "INFO"

    Write-Log "`nConnection String:" "INFO"
    Write-Log "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$Key;TableEndpoint=https://$StorageAccountName.table.core.windows.net/;" "INFO"

    Write-Log "`nTable Storage Features:" "INFO"
    Write-Log "- NoSQL key-value store" "INFO"
    Write-Log "- Partition and row key structure" "INFO"
    Write-Log "- Automatic scaling" "INFO"
    Write-Log "- REST API access" "INFO"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}