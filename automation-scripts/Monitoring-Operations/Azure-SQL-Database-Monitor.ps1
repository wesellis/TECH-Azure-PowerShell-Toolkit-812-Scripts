# ============================================================================
# Script Name: Azure SQL Database Performance Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure SQL Database performance, DTU usage, and connection status
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$ServerName,
    [string]$DatabaseName
)

Write-Host "Monitoring SQL Database: $DatabaseName"
Write-Host "Server: $ServerName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get SQL Server details
$SqlServer = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName

Write-Host "SQL Server Information:"
Write-Host "  Server Name: $($SqlServer.ServerName)"
Write-Host "  Location: $($SqlServer.Location)"
Write-Host "  Server Version: $($SqlServer.ServerVersion)"
Write-Host "  Fully Qualified Domain Name: $($SqlServer.FullyQualifiedDomainName)"

# Get SQL Database details
$SqlDatabase = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

Write-Host "`nSQL Database Information:"
Write-Host "  Database Name: $($SqlDatabase.DatabaseName)"
Write-Host "  Status: $($SqlDatabase.Status)"
Write-Host "  Edition: $($SqlDatabase.Edition)"
Write-Host "  Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)"
Write-Host "  Max Size (GB): $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2))"
Write-Host "  Collation: $($SqlDatabase.CollationName)"
Write-Host "  Creation Date: $($SqlDatabase.CreationDate)"
Write-Host "  Earliest Restore Date: $($SqlDatabase.EarliestRestoreDate)"

# Check firewall rules
$FirewallRules = Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName
Write-Host "`nFirewall Rules: $($FirewallRules.Count)"
foreach ($Rule in $FirewallRules) {
    Write-Host "  - $($Rule.FirewallRuleName): $($Rule.StartIpAddress) - $($Rule.EndIpAddress)"
}

# Get database usage metrics (simplified)
Write-Host "`nDatabase Metrics:"
Write-Host "  Note: Use Azure Monitor or Azure Portal for detailed performance metrics"
Write-Host "  Current Service Level: $($SqlDatabase.CurrentServiceObjectiveName)"

Write-Host "`nSQL Database monitoring completed at $(Get-Date)"
