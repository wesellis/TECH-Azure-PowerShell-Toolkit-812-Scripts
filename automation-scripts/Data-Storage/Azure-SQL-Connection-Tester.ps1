<#
.SYNOPSIS
    Manage SQL resources

.DESCRIPTION
    Manage SQL resources
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [Parameter(Mandatory)]
    [string]$ServerName,
    [Parameter(Mandatory)]
    [string]$DatabaseName,
    [Parameter(Mandatory)]
    [string]$Username,
    [Parameter(Mandatory)]
    [securestring]$Password
)
Write-Host "Testing connection to SQL Database: $DatabaseName"
$ConnectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
try {
    $Connection = New-Object -ErrorAction Stop System.Data.SqlClient.SqlConnection
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()
    Write-Host "Connection successful!"
    Write-Host "Server: $ServerName.database.windows.net"
    Write-Host "Database: $DatabaseName"
    Write-Host "Status: Connected"
    $Connection.Close()
} catch {
    Write-Host "Connection failed!"
    Write-Host "Error: $($_.Exception.Message)"
}

