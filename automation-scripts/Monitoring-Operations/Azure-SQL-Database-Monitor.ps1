#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$ResourceGroupName,
    [string]$ServerName,
    [string]$DatabaseName
)

#region Functions

Write-Information "Monitoring SQL Database: $DatabaseName"
Write-Information "Server: $ServerName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get SQL Server details
$SqlServer = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName

Write-Information "SQL Server Information:"
Write-Information "  Server Name: $($SqlServer.ServerName)"
Write-Information "  Location: $($SqlServer.Location)"
Write-Information "  Server Version: $($SqlServer.ServerVersion)"
Write-Information "  Fully Qualified Domain Name: $($SqlServer.FullyQualifiedDomainName)"

# Get SQL Database details
$SqlDatabase = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

Write-Information "`nSQL Database Information:"
Write-Information "  Database Name: $($SqlDatabase.DatabaseName)"
Write-Information "  Status: $($SqlDatabase.Status)"
Write-Information "  Edition: $($SqlDatabase.Edition)"
Write-Information "  Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)"
Write-Information "  Max Size (GB): $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2))"
Write-Information "  Collation: $($SqlDatabase.CollationName)"
Write-Information "  Creation Date: $($SqlDatabase.CreationDate)"
Write-Information "  Earliest Restore Date: $($SqlDatabase.EarliestRestoreDate)"

# Check firewall rules
$FirewallRules = Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName
Write-Information "`nFirewall Rules: $($FirewallRules.Count)"
foreach ($Rule in $FirewallRules) {
    Write-Information "  - $($Rule.FirewallRuleName): $($Rule.StartIpAddress) - $($Rule.EndIpAddress)"
}

# Get database usage metrics (simplified)
Write-Information "`nDatabase Metrics:"
Write-Information "  Note: Use Azure Monitor or Azure Portal for detailed performance metrics"
Write-Information "  Current Service Level: $($SqlDatabase.CurrentServiceObjectiveName)"

Write-Information "`nSQL Database monitoring completed at $(Get-Date)"


#endregion
