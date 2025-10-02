#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Sql Database Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
    [string]$DatabaseName
)
Write-Output "Monitoring SQL Database: $DatabaseName" "INFO"
Write-Output "Server: $ServerName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output " ============================================" "INFO"
    $SqlServer = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName
Write-Output "SQL Server Information:" "INFO"
Write-Output "Server Name: $($SqlServer.ServerName)" "INFO"
Write-Output "Location: $($SqlServer.Location)" "INFO"
Write-Output "Server Version: $($SqlServer.ServerVersion)" "INFO"
Write-Output "Fully Qualified Domain Name: $($SqlServer.FullyQualifiedDomainName)" "INFO"
    $SqlDatabase = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
Write-Output " `nSQL Database Information:" "INFO"
Write-Output "Database Name: $($SqlDatabase.DatabaseName)" "INFO"
Write-Output "Status: $($SqlDatabase.Status)" "INFO"
Write-Output "Edition: $($SqlDatabase.Edition)" "INFO"
Write-Output "Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)" "INFO"
Write-Output "Max Size (GB): $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2))" "INFO"
Write-Output "Collation: $($SqlDatabase.CollationName)" "INFO"
Write-Output "Creation Date: $($SqlDatabase.CreationDate)" "INFO"
Write-Output "Earliest Restore Date: $($SqlDatabase.EarliestRestoreDate)" "INFO"
    $FirewallRules = Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName
Write-Output " `nFirewall Rules: $($FirewallRules.Count)" "INFO"
foreach ($Rule in $FirewallRules) {
    Write-Output "  - $($Rule.FirewallRuleName): $($Rule.StartIpAddress) - $($Rule.EndIpAddress)" "INFO"
}
Write-Output " `nDatabase Metrics:" "INFO"
Write-Output "Note: Use Azure Monitor or Azure Portal for  performance metrics" "INFO"
Write-Output "Current Service Level: $($SqlDatabase.CurrentServiceObjectiveName)" "INFO"
Write-Output " `nSQL Database monitoring completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
