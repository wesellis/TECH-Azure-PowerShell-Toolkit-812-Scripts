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
    [string]$DatabaseName,
    [string]$Location,
    [string]$AdminUser,
    [securestring]$AdminPassword,
    [string]$Edition = "Standard",
    [string]$ServiceObjective = "S0",
    [bool]$AllowAzureIps = $true
)

#region Functions

Write-Information "Provisioning SQL Database: $DatabaseName"
Write-Information "SQL Server: $ServerName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Edition: $Edition"
Write-Information "Service Objective: $ServiceObjective"

# Create SQL Server
Write-Information "`nCreating SQL Server..."
$params = @{
    ResourceGroupName = $ResourceGroupName
    ServerName = $ServerName
    Location = $Location
    SqlAdministratorCredentials = "(New-Object"
    ErrorAction = "Stop PSCredential($AdminUser, $AdminPassword))"
}
$SqlServer @params

Write-Information "SQL Server created: $($SqlServer.FullyQualifiedDomainName)"

# Configure firewall rule to allow Azure services
if ($AllowAzureIps) {
    Write-Information "Configuring firewall to allow Azure services..."
    $params = @{
        ResourceGroupName = $ResourceGroupName
        StartIpAddress = "0.0.0.0"
        ServerName = $ServerName
        EndIpAddress = "0.0.0.0"
        ErrorAction = "Stop"
        FirewallRuleName = "AllowAzureServices"
    }
    New-AzSqlServerFirewallRule @params
}

# Create SQL Database
Write-Information "`nCreating SQL Database..."
$params = @{
    ResourceGroupName = $ResourceGroupName
    Edition = $Edition
    ServerName = $ServerName
    RequestedServiceObjectiveName = $ServiceObjective
    DatabaseName = $DatabaseName
    ErrorAction = "Stop"
}
$SqlDatabase @params

Write-Information "`nSQL Database $DatabaseName provisioned successfully"
Write-Information "Server: $($SqlServer.FullyQualifiedDomainName)"
Write-Information "Database: $($SqlDatabase.DatabaseName)"
Write-Information "Edition: $($SqlDatabase.Edition)"
Write-Information "Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)"
Write-Information "Max Size: $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2)) GB"

Write-Information "`nConnection String (template):"
Write-Information "Server=tcp:$($SqlServer.FullyQualifiedDomainName),1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$AdminUser;Password=***;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Information "`nSQL Database provisioning completed at $(Get-Date)"


#endregion
