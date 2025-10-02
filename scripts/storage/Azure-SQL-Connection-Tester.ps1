#Requires -Version 7.4
#Requires -Modules Az.Sql

<#`n.SYNOPSIS
    Manage SQL resources

.DESCRIPTION
    Manage SQL resources
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ServerName,
    [Parameter(Mandatory)]
    [string]$DatabaseName,
    [Parameter(Mandatory)]
    [string]$Username,
    [Parameter(Mandatory)]
    [securestring]$Password
)
Write-Output "Testing connection to SQL Database: $DatabaseName"
$ConnectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
try {
    $Connection = New-Object -ErrorAction Stop System.Data.SqlClient.SqlConnection
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()
    Write-Output "Connection successful!"
    Write-Output "Server: $ServerName.database.windows.net"
    Write-Output "Database: $DatabaseName"
    Write-Output "Status: Connected"
    $Connection.Close()
} catch {
    Write-Output "Connection failed!"
    Write-Output "Error: $($_.Exception.Message)"`n}
