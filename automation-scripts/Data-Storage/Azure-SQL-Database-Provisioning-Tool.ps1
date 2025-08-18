# ============================================================================
# Script Name: Azure SQL Database Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure SQL Server and Database with security configurations
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$ServerName,
    [string]$DatabaseName,
    [string]$Location,
    [string]$AdminUser,
    [securestring]$AdminPassword,
    [string]$Edition = "Standard",
    [string]$ServiceObjective = "S0",
    [bool]$AllowAzureIps = $true
)

Write-Information "Provisioning SQL Database: $DatabaseName"
Write-Information "SQL Server: $ServerName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Edition: $Edition"
Write-Information "Service Objective: $ServiceObjective"

# Create SQL Server
Write-Information "`nCreating SQL Server..."
$SqlServer = New-AzSqlServer -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -ServerName $ServerName `
    -SqlAdministratorCredentials (New-Object -ErrorAction Stop PSCredential($AdminUser, $AdminPassword))

Write-Information "SQL Server created: $($SqlServer.FullyQualifiedDomainName)"

# Configure firewall rule to allow Azure services
if ($AllowAzureIps) {
    Write-Information "Configuring firewall to allow Azure services..."
    New-AzSqlServerFirewallRule -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -FirewallRuleName "AllowAzureServices" `
        -StartIpAddress "0.0.0.0" `
        -EndIpAddress "0.0.0.0"
}

# Create SQL Database
Write-Information "`nCreating SQL Database..."
$SqlDatabase = New-AzSqlDatabase -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -DatabaseName $DatabaseName `
    -Edition $Edition `
    -RequestedServiceObjectiveName $ServiceObjective

Write-Information "`nSQL Database $DatabaseName provisioned successfully"
Write-Information "Server: $($SqlServer.FullyQualifiedDomainName)"
Write-Information "Database: $($SqlDatabase.DatabaseName)"
Write-Information "Edition: $($SqlDatabase.Edition)"
Write-Information "Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)"
Write-Information "Max Size: $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2)) GB"

Write-Information "`nConnection String (template):"
Write-Information "Server=tcp:$($SqlServer.FullyQualifiedDomainName),1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$AdminUser;Password=***;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Information "`nSQL Database provisioning completed at $(Get-Date)"
