#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Sql

<#
.SYNOPSIS
    Azure SQL Database Provisioning Tool

.DESCRIPTION
    Azure automation for provisioning SQL databases

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUser,

    [Parameter(Mandatory)]
    [securestring]$AdminPassword,

    [Parameter()]
    $Edition = "Standard",

    [Parameter()]
    $ServiceObjective = "S0",

    [Parameter()]
    [bool]$AllowAzureIps = $true
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        $Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [SQL-DB] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Provisioning SQL Database: $DatabaseName" "INFO"
    Write-Log "SQL Server: $ServerName" "INFO"
    Write-Log "Resource Group: $ResourceGroupName" "INFO"
    Write-Log "Location: $Location" "INFO"
    Write-Log "Edition: $Edition" "INFO"
    Write-Log "Service Objective: $ServiceObjective" "INFO"

    # Check if SQL Server exists
    $SqlServer = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ErrorAction SilentlyContinue

    if (-not $SqlServer) {
        Write-Log "Creating SQL Server..." "INFO"

        $params = @{
            ResourceGroupName = $ResourceGroupName
            ServerName = $ServerName
            Location = $Location
            SqlAdministratorCredentials = (New-Object PSCredential($AdminUser, $AdminPassword))
            ErrorAction = "Stop"
        }

        $SqlServer = New-AzSqlServer @params
        Write-Log "SQL Server created: $($SqlServer.FullyQualifiedDomainName)" "SUCCESS"
    } else {
        Write-Log "SQL Server already exists: $($SqlServer.FullyQualifiedDomainName)" "INFO"
    }

    if ($AllowAzureIps) {
        Write-Log "Configuring firewall to allow Azure services..." "INFO"

        $firewallParams = @{
            ResourceGroupName = $ResourceGroupName
            ServerName = $ServerName
            FirewallRuleName = "AllowAllAzureIps"
            StartIpAddress = "0.0.0.0"
            EndIpAddress = "0.0.0.0"
            ErrorAction = "Stop"
        }

        New-AzSqlServerFirewallRule @firewallParams
        Write-Log "Firewall rule configured" "SUCCESS"
    }

    # Create the database
    Write-Log "Creating database..." "INFO"

    $dbParams = @{
        ResourceGroupName = $ResourceGroupName
        ServerName = $ServerName
        DatabaseName = $DatabaseName
        Edition = $Edition
        RequestedServiceObjectiveName = $ServiceObjective
        ErrorAction = "Stop"
    }

    $Database = New-AzSqlDatabase @dbParams

    Write-Log "Database created successfully!" "SUCCESS"
    Write-Log "Database: $DatabaseName" "INFO"
    Write-Log "Server: $($SqlServer.FullyQualifiedDomainName)" "INFO"
    Write-Log "Edition: $($Database.Edition)" "INFO"
    Write-Log "Service Objective: $($Database.CurrentServiceObjectiveName)" "INFO"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}