#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Sql Database Monitor

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
    [string]$DatabaseName
)
Write-Host "Monitoring SQL Database: $DatabaseName" "INFO"
Write-Host "Server: $ServerName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host " ============================================" "INFO"
$SqlServer = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName
Write-Host "SQL Server Information:" "INFO"
Write-Host "Server Name: $($SqlServer.ServerName)" "INFO"
Write-Host "Location: $($SqlServer.Location)" "INFO"
Write-Host "Server Version: $($SqlServer.ServerVersion)" "INFO"
Write-Host "Fully Qualified Domain Name: $($SqlServer.FullyQualifiedDomainName)" "INFO"

$SqlDatabase = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
Write-Host " `nSQL Database Information:" "INFO"
Write-Host "Database Name: $($SqlDatabase.DatabaseName)" "INFO"
Write-Host "Status: $($SqlDatabase.Status)" "INFO"
Write-Host "Edition: $($SqlDatabase.Edition)" "INFO"
Write-Host "Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)" "INFO"
Write-Host "Max Size (GB): $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2))" "INFO"
Write-Host "Collation: $($SqlDatabase.CollationName)" "INFO"
Write-Host "Creation Date: $($SqlDatabase.CreationDate)" "INFO"
Write-Host "Earliest Restore Date: $($SqlDatabase.EarliestRestoreDate)" "INFO"

$FirewallRules = Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName
Write-Host " `nFirewall Rules: $($FirewallRules.Count)" "INFO"
foreach ($Rule in $FirewallRules) {
    Write-Host "  - $($Rule.FirewallRuleName): $($Rule.StartIpAddress) - $($Rule.EndIpAddress)" "INFO"
}
Write-Host " `nDatabase Metrics:" "INFO"
Write-Host "Note: Use Azure Monitor or Azure Portal for  performance metrics" "INFO"
Write-Host "Current Service Level: $($SqlDatabase.CurrentServiceObjectiveName)" "INFO"
Write-Host " `nSQL Database monitoring completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


