#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Sql

<#`n.SYNOPSIS
    Create Azure SQL Database

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
Create SQL Server and database
.PARAMETER ResourceGroup
Resource group name
.PARAMETER ServerName
SQL Server name (must be unique)
.PARAMETER DatabaseName
Database name
.PARAMETER Location
Azure region
.PARAMETER AdminUser
SQL admin username
.PARAMETER AdminPassword
SQL admin password (SecureString)
.EXAMPLE
$pwd = Read-Host -AsSecureString
.
ew-SqlDatabase.ps1 -ResourceGroup rg-sql -ServerName mysqlserver -DatabaseName mydb -Location "East US" -AdminUser sqladmin -AdminPassword $pwd
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroup,
    [Parameter(Mandatory)]
    [string]$ServerName,
    [Parameter(Mandatory)]
    [string]$DatabaseName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter(Mandatory)]
    [string]$AdminUser,
    [Parameter(Mandatory)]
    [SecureString]$AdminPassword
)
$cred = New-Object PSCredential($AdminUser, $AdminPassword)
Write-Output "Creating SQL Server $ServerName" # Color: $2
$SqlserverSplat = @{
    ResourceGroupName = $ResourceGroup
    ServerName = $ServerName
    Location = $Location
    SqlAdministratorCredentials = $cred
}
New-AzSqlServer @sqlserverSplat
Write-Output "Creating database $DatabaseName" # Color: $2
$SqldatabaseSplat = @{
    ResourceGroupName = $ResourceGroup
    ServerName = $ServerName
    DatabaseName = $DatabaseName
    Edition = "Standard"
    RequestedServiceObjectiveName = "S0"
}
New-AzSqlDatabase @sqldatabaseSplat
Write-Output "SQL Database created successfully" # Color: $2
Write-Output "Server: $($server.FullyQualifiedDomainName)"
Write-Output "Database: $DatabaseName"
return @{Server = $server; Database = $db`n}
