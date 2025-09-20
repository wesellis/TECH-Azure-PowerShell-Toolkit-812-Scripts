<#
.SYNOPSIS
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
.\New-SqlDatabase.ps1 -ResourceGroup rg-sql -ServerName mysqlserver -DatabaseName mydb -Location "East US" -AdminUser sqladmin -AdminPassword $pwd
#>
param(
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
$server = New-AzSqlServer -ResourceGroupName $ResourceGroup -ServerName $ServerName -Location $Location -SqlAdministratorCredentials $cred
Write-Host "Creating database $DatabaseName" -ForegroundColor Green
$db = New-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $ServerName -DatabaseName $DatabaseName -Edition Standard -RequestedServiceObjectiveName S0
Write-Host "SQL Database created successfully" -ForegroundColor Green
Write-Host "Server: $($server.FullyQualifiedDomainName)"
Write-Host "Database: $DatabaseName"
return @{Server = $server; Database = $db}

