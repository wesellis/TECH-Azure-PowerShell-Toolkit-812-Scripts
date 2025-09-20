#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Sql

<#`n.SYNOPSIS
    Create Azure SQL Database

.DESCRIPTION
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
Write-Host "Creating SQL Server $ServerName" -ForegroundColor Green
$sqlserverSplat = @{
    ResourceGroupName = $ResourceGroup
    ServerName = $ServerName
    Location = $Location
    SqlAdministratorCredentials = $cred
}
New-AzSqlServer @sqlserverSplat
Write-Host "Creating database $DatabaseName" -ForegroundColor Green
$sqldatabaseSplat = @{
    ResourceGroupName = $ResourceGroup
    ServerName = $ServerName
    DatabaseName = $DatabaseName
    Edition = "Standard"
    RequestedServiceObjectiveName = "S0"
}
New-AzSqlDatabase @sqldatabaseSplat
Write-Host "SQL Database created successfully" -ForegroundColor Green
Write-Host "Server: $($server.FullyQualifiedDomainName)"
Write-Host "Database: $DatabaseName"
return @{Server = $server; Database = $db}


