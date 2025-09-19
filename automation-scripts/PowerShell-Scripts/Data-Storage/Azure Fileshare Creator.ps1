#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Fileshare Creator

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
    We Enhanced Azure Fileshare Creator

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEShareName,
    
    [Parameter(Mandatory=$false)]
    [int]$WEQuotaInGB = 1024
)

#region Functions

Write-WELog " Creating File Share: $WEShareName" " INFO"

$WEStorageAccount = Get-AzStorageAccount -ResourceGroupName $WEResourceGroupName -Name $WEStorageAccountName
$WEContext = $WEStorageAccount.Context

$params = @{
    ErrorAction = "Stop"
    Context = $WEContext
    QuotaGiB = $WEQuotaInGB
    Name = $WEShareName
}
$WEFileShare @params

Write-WELog "  File Share created successfully:" " INFO"
Write-WELog "  Name: $($WEFileShare.Name)" " INFO"
Write-WELog "  Quota: $WEQuotaInGB GB" " INFO"
Write-WELog "  Storage Account: $WEStorageAccountName" " INFO"

; 
$WEKeys = Get-AzStorageAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEStorageAccountName; 
$WEKey = $WEKeys[0].Value

Write-WELog " `nConnection Information:" " INFO"
Write-WELog "  UNC Path: \\$WEStorageAccountName.file.core.windows.net\$WEShareName" " INFO"
Write-WELog "  Mount Command (Windows):" " INFO"
Write-WELog "    net use Z: \\$WEStorageAccountName.file.core.windows.net\$WEShareName /u:AZURE\$WEStorageAccountName $WEKey" " INFO"
Write-WELog "  Mount Command (Linux):" " INFO"
Write-WELog "    sudo mount -t cifs //$WEStorageAccountName.file.core.windows.net/$WEShareName /mnt/myfileshare -o vers=3.0,username=$WEStorageAccountName,password=$WEKey,dir_mode=0777,file_mode=0777" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
