#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage SQL resources

.DESCRIPTION
    Manage SQL resources
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$ServerName,
    [string]$DatabaseName
)
Write-Output "Monitoring SQL Database: $DatabaseName"
Write-Output "Server: $ServerName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$SqlServer = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName
Write-Output "SQL Server Information:"
Write-Output "Server Name: $($SqlServer.ServerName)"
Write-Output "Location: $($SqlServer.Location)"
Write-Output "Server Version: $($SqlServer.ServerVersion)"
Write-Output "Fully Qualified Domain Name: $($SqlServer.FullyQualifiedDomainName)"
$SqlDatabase = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
Write-Output "`nSQL Database Information:"
Write-Output "Database Name: $($SqlDatabase.DatabaseName)"
Write-Output "Status: $($SqlDatabase.Status)"
Write-Output "Edition: $($SqlDatabase.Edition)"
Write-Output "Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)"
Write-Output "Max Size (GB): $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2))"
Write-Output "Collation: $($SqlDatabase.CollationName)"
Write-Output "Creation Date: $($SqlDatabase.CreationDate)"
Write-Output "Earliest Restore Date: $($SqlDatabase.EarliestRestoreDate)"
$FirewallRules = Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName
Write-Output "`nFirewall Rules: $($FirewallRules.Count)"
foreach ($Rule in $FirewallRules) {
    Write-Output "  - $($Rule.FirewallRuleName): $($Rule.StartIpAddress) - $($Rule.EndIpAddress)"
}
Write-Output "`nDatabase Metrics:"
Write-Output "Note: Use Azure Monitor or Azure Portal for  performance metrics"
Write-Output "Current Service Level: $($SqlDatabase.CurrentServiceObjectiveName)"
Write-Output "`nSQL Database monitoring completed at $(Get-Date)"



