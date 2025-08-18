<#
.SYNOPSIS
    Azure Sql Elasticpool Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
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

Write-WELog " Creating SQL Elastic Pool: $WEElasticPoolName" " INFO"
; 
$WEElasticPool = New-AzSqlElasticPool `
    -ResourceGroupName $WEResourceGroupName `
    -ServerName $WEServerName `
    -ElasticPoolName $WEElasticPoolName `
    -Edition $WEEdition `
    -Dtu $WEPoolDtu `
    -DatabaseDtuMin $WEDatabaseDtuMin `
    -DatabaseDtuMax $WEDatabaseDtuMax

Write-WELog " ✅ SQL Elastic Pool created successfully:" " INFO"
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
