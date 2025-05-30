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

Write-Host "Provisioning SQL Database: $DatabaseName"
Write-Host "SQL Server: $ServerName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Edition: $Edition"
Write-Host "Service Objective: $ServiceObjective"

# Create SQL Server
Write-Host "`nCreating SQL Server..."
$SqlServer = New-AzSqlServer `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -ServerName $ServerName `
    -SqlAdministratorCredentials (New-Object PSCredential($AdminUser, $AdminPassword))

Write-Host "SQL Server created: $($SqlServer.FullyQualifiedDomainName)"

# Configure firewall rule to allow Azure services
if ($AllowAzureIps) {
    Write-Host "Configuring firewall to allow Azure services..."
    New-AzSqlServerFirewallRule `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -FirewallRuleName "AllowAzureServices" `
        -StartIpAddress "0.0.0.0" `
        -EndIpAddress "0.0.0.0"
}

# Create SQL Database
Write-Host "`nCreating SQL Database..."
$SqlDatabase = New-AzSqlDatabase `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -DatabaseName $DatabaseName `
    -Edition $Edition `
    -RequestedServiceObjectiveName $ServiceObjective

Write-Host "`nSQL Database $DatabaseName provisioned successfully"
Write-Host "Server: $($SqlServer.FullyQualifiedDomainName)"
Write-Host "Database: $($SqlDatabase.DatabaseName)"
Write-Host "Edition: $($SqlDatabase.Edition)"
Write-Host "Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)"
Write-Host "Max Size: $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2)) GB"

Write-Host "`nConnection String (template):"
Write-Host "Server=tcp:$($SqlServer.FullyQualifiedDomainName),1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$AdminUser;Password=***;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "`nSQL Database provisioning completed at $(Get-Date)"
