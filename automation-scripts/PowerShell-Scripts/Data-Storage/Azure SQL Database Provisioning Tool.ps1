<#
.SYNOPSIS
    Azure Sql Database Provisioning Tool

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUser,
    [securestring]$AdminPassword,
    [string]$Edition = "Standard" ,
    [string]$ServiceObjective = "S0" ,
    [bool]$AllowAzureIps = $true
)
Write-Host "Provisioning SQL Database: $DatabaseName" "INFO"
Write-Host "SQL Server: $ServerName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host "Location: $Location" "INFO"
Write-Host "Edition: $Edition" "INFO"
Write-Host "Service Objective: $ServiceObjective" "INFO"
Write-Host " `nCreating SQL Server..." "INFO";
$params = @{
    ResourceGroupName = $ResourceGroupName
    ServerName = $ServerName
    Location = $Location
    SqlAdministratorCredentials = "(New-Object"
    ErrorAction = "Stop PSCredential($AdminUser, $AdminPassword))"
}
$SqlServer @params
Write-Host "SQL Server created: $($SqlServer.FullyQualifiedDomainName)" "INFO"
if ($AllowAzureIps) {
    Write-Host "Configuring firewall to allow Azure services..." "INFO"
    $params = @{
        ResourceGroupName = $ResourceGroupName
        StartIpAddress = " 0.0.0.0"
        ServerName = $ServerName
        EndIpAddress = " 0.0.0.0"
        ErrorAction = "Stop"
        FirewallRuleName = "AllowAzureServices"
    }
    New-AzSqlServerFirewallRule @params
}
Write-Host " `nCreating SQL Database..." "INFO" ;
$params = @{
    ResourceGroupName = $ResourceGroupName
    Edition = $Edition
    ServerName = $ServerName
    RequestedServiceObjectiveName = $ServiceObjective
    DatabaseName = $DatabaseName
    ErrorAction = "Stop"
}
$SqlDatabase @params
Write-Host " `nSQL Database $DatabaseName provisioned successfully" "INFO"
Write-Host "Server: $($SqlServer.FullyQualifiedDomainName)" "INFO"
Write-Host "Database: $($SqlDatabase.DatabaseName)" "INFO"
Write-Host "Edition: $($SqlDatabase.Edition)" "INFO"
Write-Host "Service Objective: $($SqlDatabase.CurrentServiceObjectiveName)" "INFO"
Write-Host "Max Size: $([math]::Round($SqlDatabase.MaxSizeBytes / 1GB, 2)) GB" "INFO"
Write-Host " `nConnection String (template):" "INFO"
Write-Host "Server=tcp:$($SqlServer.FullyQualifiedDomainName),1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$AdminUser;Password=***;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" "INFO"
Write-Host " `nSQL Database provisioning completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

