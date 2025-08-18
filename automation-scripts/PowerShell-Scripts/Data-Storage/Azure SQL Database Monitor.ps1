<#
.SYNOPSIS
    Azure Sql Database Monitor

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
    We Enhanced Azure Sql Database Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerName,
    [string]$WEDatabaseName
)

Write-WELog " Monitoring SQL Database: $WEDatabaseName" " INFO"
Write-WELog " Server: $WEServerName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"


$WESqlServer = Get-AzSqlServer -ResourceGroupName $WEResourceGroupName -ServerName $WEServerName

Write-WELog " SQL Server Information:" " INFO"
Write-WELog "  Server Name: $($WESqlServer.ServerName)" " INFO"
Write-WELog "  Location: $($WESqlServer.Location)" " INFO"
Write-WELog "  Server Version: $($WESqlServer.ServerVersion)" " INFO"
Write-WELog "  Fully Qualified Domain Name: $($WESqlServer.FullyQualifiedDomainName)" " INFO"

; 
$WESqlDatabase = Get-AzSqlDatabase -ResourceGroupName $WEResourceGroupName -ServerName $WEServerName -DatabaseName $WEDatabaseName

Write-WELog " `nSQL Database Information:" " INFO"
Write-WELog "  Database Name: $($WESqlDatabase.DatabaseName)" " INFO"
Write-WELog "  Status: $($WESqlDatabase.Status)" " INFO"
Write-WELog "  Edition: $($WESqlDatabase.Edition)" " INFO"
Write-WELog "  Service Objective: $($WESqlDatabase.CurrentServiceObjectiveName)" " INFO"
Write-WELog "  Max Size (GB): $([math]::Round($WESqlDatabase.MaxSizeBytes / 1GB, 2))" " INFO"
Write-WELog "  Collation: $($WESqlDatabase.CollationName)" " INFO"
Write-WELog "  Creation Date: $($WESqlDatabase.CreationDate)" " INFO"
Write-WELog "  Earliest Restore Date: $($WESqlDatabase.EarliestRestoreDate)" " INFO"

; 
$WEFirewallRules = Get-AzSqlServerFirewallRule -ResourceGroupName $WEResourceGroupName -ServerName $WEServerName
Write-WELog " `nFirewall Rules: $($WEFirewallRules.Count)" " INFO"
foreach ($WERule in $WEFirewallRules) {
    Write-WELog "  - $($WERule.FirewallRuleName): $($WERule.StartIpAddress) - $($WERule.EndIpAddress)" " INFO"
}


Write-WELog " `nDatabase Metrics:" " INFO"
Write-WELog "  Note: Use Azure Monitor or Azure Portal for detailed performance metrics" " INFO"
Write-WELog "  Current Service Level: $($WESqlDatabase.CurrentServiceObjectiveName)" " INFO"

Write-WELog " `nSQL Database monitoring completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
