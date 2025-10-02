#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Sql Connection Tester

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
;
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Username,
    [Parameter(Mandatory)]
    [securestring]$Password
)
Write-Output "Testing connection to SQL Database: $DatabaseName" "INFO"
    $ConnectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
try {
    $Connection = New-Object -ErrorAction Stop System.Data.SqlClient.SqlConnection
    [string]$Connection.ConnectionString = $ConnectionString
    [string]$Connection.Open()
    Write-Output "Connection successful!" "INFO"
    Write-Output "Server: $ServerName.database.windows.net" "INFO"
    Write-Output "Database: $DatabaseName" "INFO"
    Write-Output "Status: Connected" "INFO"
    [string]$Connection.Close()
} catch {
    Write-Output "Connection failed!" "INFO"
    Write-Output "Error: $($_.Exception.Message)" "INFO"`n}
