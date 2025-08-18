# ============================================================================
# Script Name: Azure SQL Database Connection Tester
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Tests connectivity to Azure SQL Database
# ============================================================================

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

Write-Information "Testing connection to SQL Database: $DatabaseName"

$ConnectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

try {
    $Connection = New-Object -ErrorAction Stop System.Data.SqlClient.SqlConnection
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()
    
    Write-Information "✅ Connection successful!"
    Write-Information "  Server: $ServerName.database.windows.net"
    Write-Information "  Database: $DatabaseName"
    Write-Information "  Status: Connected"
    
    $Connection.Close()
} catch {
    Write-Information "❌ Connection failed!"
    Write-Information "  Error: $($_.Exception.Message)"
}
