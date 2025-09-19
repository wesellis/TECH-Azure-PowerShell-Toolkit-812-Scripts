#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Sql Elasticpool Creator

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
    We Enhanced Azure Sql Elasticpool Creator

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

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEElasticPoolName,
    
    [Parameter(Mandatory=$false)]
    [string]$WEEdition = " Standard" ,
    
    [Parameter(Mandatory=$false)]
    [int]$WEPoolDtu = 100,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDatabaseDtuMin = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDatabaseDtuMax = 100
)

#region Functions

Write-WELog " Creating SQL Elastic Pool: $WEElasticPoolName" " INFO"
; 
$params = @{
    ResourceGroupName = $WEResourceGroupName
    Dtu = $WEPoolDtu
    Edition = $WEEdition
    DatabaseDtuMax = $WEDatabaseDtuMax
    ServerName = $WEServerName
    ElasticPoolName = $WEElasticPoolName
    ErrorAction = "Stop"
    DatabaseDtuMin = $WEDatabaseDtuMin
}
$WEElasticPool @params

Write-WELog "  SQL Elastic Pool created successfully:" " INFO"
Write-WELog "  Name: $($WEElasticPool.ElasticPoolName)" " INFO"
Write-WELog "  Server: $($WEElasticPool.ServerName)" " INFO"
Write-WELog "  Edition: $($WEElasticPool.Edition)" " INFO"
Write-WELog "  Pool DTU: $($WEElasticPool.Dtu)" " INFO"
Write-WELog "  Database DTU Min: $($WEElasticPool.DatabaseDtuMin)" " INFO"
Write-WELog "  Database DTU Max: $($WEElasticPool.DatabaseDtuMax)" " INFO"
Write-WELog "  State: $($WEElasticPool.State)" " INFO"

Write-WELog " `nElastic Pool Benefits:" " INFO"
Write-WELog " • Cost optimization for multiple databases" " INFO"
Write-WELog " • Automatic resource balancing" " INFO"
Write-WELog " • Simplified management" " INFO"
Write-WELog " • Predictable pricing model" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Move existing databases to the pool" " INFO"
Write-WELog " 2. Create new databases in the pool" " INFO"
Write-WELog " 3. Monitor resource utilization" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
