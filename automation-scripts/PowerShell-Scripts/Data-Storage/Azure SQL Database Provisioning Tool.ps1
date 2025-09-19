#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Sql Database Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Sql Database Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDatabaseName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAdminUser,
    [securestring]$WEAdminPassword,
    [string]$WEEdition = " Standard" ,
    [string]$WEServiceObjective = " S0" ,
    [bool]$WEAllowAzureIps = $true
)

#region Functions

Write-WELog " Provisioning SQL Database: $WEDatabaseName" " INFO"
Write-WELog " SQL Server: $WEServerName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " Edition: $WEEdition" " INFO"
Write-WELog " Service Objective: $WEServiceObjective" " INFO"


Write-WELog " `nCreating SQL Server..." " INFO"; 
$params = @{
    ResourceGroupName = $WEResourceGroupName
    ServerName = $WEServerName
    Location = $WELocation
    SqlAdministratorCredentials = "(New-Object"
    ErrorAction = "Stop PSCredential($WEAdminUser, $WEAdminPassword))"
}
$WESqlServer @params

Write-WELog " SQL Server created: $($WESqlServer.FullyQualifiedDomainName)" " INFO"


if ($WEAllowAzureIps) {
    Write-WELog " Configuring firewall to allow Azure services..." " INFO"
    $params = @{
        ResourceGroupName = $WEResourceGroupName
        StartIpAddress = " 0.0.0.0"
        ServerName = $WEServerName
        EndIpAddress = " 0.0.0.0"
        ErrorAction = "Stop"
        FirewallRuleName = " AllowAzureServices"
    }
    New-AzSqlServerFirewallRule @params
}


Write-WELog " `nCreating SQL Database..." " INFO" ; 
$params = @{
    ResourceGroupName = $WEResourceGroupName
    Edition = $WEEdition
    ServerName = $WEServerName
    RequestedServiceObjectiveName = $WEServiceObjective
    DatabaseName = $WEDatabaseName
    ErrorAction = "Stop"
}
$WESqlDatabase @params

Write-WELog " `nSQL Database $WEDatabaseName provisioned successfully" " INFO"
Write-WELog " Server: $($WESqlServer.FullyQualifiedDomainName)" " INFO"
Write-WELog " Database: $($WESqlDatabase.DatabaseName)" " INFO"
Write-WELog " Edition: $($WESqlDatabase.Edition)" " INFO"
Write-WELog " Service Objective: $($WESqlDatabase.CurrentServiceObjectiveName)" " INFO"
Write-WELog " Max Size: $([math]::Round($WESqlDatabase.MaxSizeBytes / 1GB, 2)) GB" " INFO"

Write-WELog " `nConnection String (template):" " INFO"
Write-WELog " Server=tcp:$($WESqlServer.FullyQualifiedDomainName),1433;Initial Catalog=$WEDatabaseName;Persist Security Info=False;User ID=$WEAdminUser;Password=***;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" " INFO"

Write-WELog " `nSQL Database provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
