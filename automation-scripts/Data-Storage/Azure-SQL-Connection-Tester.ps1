#Requires -Version 7.0

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
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [securestring]$Password
)

#region Functions

Write-Information "Testing connection to SQL Database: $DatabaseName"

$ConnectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

try {
    $Connection = New-Object -ErrorAction Stop System.Data.SqlClient.SqlConnection
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()
    
    Write-Information " Connection successful!"
    Write-Information "  Server: $ServerName.database.windows.net"
    Write-Information "  Database: $DatabaseName"
    Write-Information "  Status: Connected"
    
    $Connection.Close()
} catch {
    Write-Information " Connection failed!"
    Write-Information "  Error: $($_.Exception.Message)"
}


#endregion
