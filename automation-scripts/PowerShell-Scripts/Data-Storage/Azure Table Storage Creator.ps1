#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Table Storage Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Table Storage Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEStorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$WETableName
)

#region Functions

Write-WELog " Creating Table Storage: $WETableName" " INFO"

$WEStorageAccount = Get-AzStorageAccount -ResourceGroupName $WEResourceGroupName -Name $WEStorageAccountName
$WEContext = $WEStorageAccount.Context

$WETable = New-AzStorageTable -Name $WETableName -Context $WEContext

Write-WELog "  Table Storage created successfully:" " INFO"
Write-WELog "  Name: $($WETable.Name)" " INFO"
Write-WELog "  Storage Account: $WEStorageAccountName" " INFO"
Write-WELog "  Context: $($WEContext.StorageAccountName)" " INFO"

; 
$WEKeys = Get-AzStorageAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEStorageAccountName; 
$WEKey = $WEKeys[0].Value

Write-WELog " `nConnection Information:" " INFO"
Write-WELog "  Table Endpoint: https://$WEStorageAccountName.table.core.windows.net/" " INFO"
Write-WELog "  Table Name: $WETableName" " INFO"
Write-WELog "  Access Key: $($WEKey.Substring(0,8))..." " INFO"

Write-WELog " `nConnection String:" " INFO"
Write-WELog "  DefaultEndpointsProtocol=https;AccountName=$WEStorageAccountName;AccountKey=$WEKey;TableEndpoint=https://$WEStorageAccountName.table.core.windows.net/;" " INFO"

Write-WELog " `nTable Storage Features:" " INFO"
Write-WELog " • NoSQL key-value store" " INFO"
Write-WELog " • Partition and row key structure" " INFO"
Write-WELog " • Automatic scaling" " INFO"
Write-WELog " • REST API access" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
